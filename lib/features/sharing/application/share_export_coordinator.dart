import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../data/share_platform_gateway.dart';
import '../domain/share_content.dart';
import 'share_message_builder.dart';

typedef SharePageRenderer = Future<List<Uint8List>> Function();

enum ShareExportResult { shared, saved, dismissed, copied }

enum ShareExportStage { render, write, share, save }

class ShareExportFailure implements Exception {
  const ShareExportFailure(this.stage, this.userMessage, [this.cause]);

  const ShareExportFailure.render([Object? cause])
    : this(ShareExportStage.render, 'No pudimos crear la tarjeta.', cause);

  final ShareExportStage stage;
  final String userMessage;
  final Object? cause;
}

class ShareExportCoordinator {
  const ShareExportCoordinator(this.gateway);

  final SharePlatformGateway gateway;

  static int _nextExportId = 0;

  Future<ShareExportResult> share({
    required ShareContent content,
    required SharePageRenderer renderPages,
  }) async {
    final pages = await _renderAll(renderPages);
    final paths = await _writeAll(pages);

    try {
      final status = await gateway.shareFiles(
        paths,
        ShareMessageBuilder.build(content),
      );
      return switch (status) {
        NativeShareStatus.success => ShareExportResult.shared,
        NativeShareStatus.dismissed => ShareExportResult.dismissed,
        NativeShareStatus.unavailable => throw const ShareExportFailure(
          ShareExportStage.share,
          'No pudimos abrir las opciones para compartir.',
        ),
      };
    } on ShareExportFailure {
      rethrow;
    } catch (error) {
      throw ShareExportFailure(
        ShareExportStage.share,
        'No pudimos compartir la tarjeta.',
        error,
      );
    } finally {
      await _cleanup(paths);
    }
  }

  Future<ShareExportResult> save({
    required ShareContent content,
    required SharePageRenderer renderPages,
  }) async {
    final pages = await _renderAll(renderPages);
    final paths = await _writeAll(pages);

    try {
      for (final filePath in paths) {
        await gateway.saveImage(filePath);
      }
      return ShareExportResult.saved;
    } catch (error) {
      throw ShareExportFailure(
        ShareExportStage.save,
        'No pudimos guardar la tarjeta en tu galería.',
        error,
      );
    } finally {
      await _cleanup(paths);
    }
  }

  Future<void> copy(ShareContent content) =>
      gateway.copyText(ShareMessageBuilder.build(content));

  Future<List<Uint8List>> _renderAll(SharePageRenderer renderPages) async {
    try {
      final pages = await renderPages();
      if (pages.isEmpty) {
        throw StateError('The renderer returned no pages.');
      }
      return pages;
    } catch (error) {
      throw ShareExportFailure.render(error);
    }
  }

  Future<List<String>> _writeAll(List<Uint8List> pages) async {
    final writtenPaths = <String>[];

    try {
      final directory = await gateway.temporaryDirectory();
      final exportId =
          '${DateTime.now().microsecondsSinceEpoch}_${_nextExportId++}';

      for (var index = 0; index < pages.length; index++) {
        final filePath = path.join(
          directory.path,
          'verbum_${exportId}_${index + 1}.png',
        );
        writtenPaths.add(filePath);
        await File(filePath).writeAsBytes(pages[index], flush: true);
      }
      return writtenPaths;
    } catch (error) {
      await _cleanup(writtenPaths);
      throw ShareExportFailure(
        ShareExportStage.write,
        'No pudimos preparar la tarjeta.',
        error,
      );
    }
  }

  Future<void> _cleanup(Iterable<String> paths) async {
    for (final filePath in paths) {
      try {
        await gateway.deleteFile(filePath);
      } catch (_) {
        // Temporary-file cleanup is best effort and must not mask the result.
      }
    }
  }
}
