import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/application/share_export_coordinator.dart';
import 'package:verbum/features/sharing/application/share_message_builder.dart';
import 'package:verbum/features/sharing/data/share_platform_gateway.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';

void main() {
  late Directory temporaryDirectory;
  late FakeSharePlatformGateway gateway;
  late ShareExportCoordinator coordinator;

  const png1 = <int>[137, 80, 78, 71, 1];
  const png2 = <int>[137, 80, 78, 71, 2];
  const png3 = <int>[137, 80, 78, 71, 3];

  final content = ShareContent(
    title: 'Palabra del día',
    body: 'Todo lo puedo en Cristo que me fortalece.',
    reference: 'Filipenses 4:13',
    kind: ShareContentKind.verse,
  );

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'verbum_share_export_test_',
    );
    gateway = FakeSharePlatformGateway(temporaryDirectory);
    coordinator = ShareExportCoordinator(gateway);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'share sends every rendered page with the complete Verbum caption',
    () async {
      final result = await coordinator.share(
        content: content,
        renderPages: () async => [
          Uint8List.fromList(png1),
          Uint8List.fromList(png2),
          Uint8List.fromList(png3),
        ],
      );

      expect(result, ShareExportResult.shared);
      expect(gateway.sharedPaths, hasLength(3));
      expect(
        gateway.sharedText,
        'Palabra del día\n\n'
        'Filipenses 4:13\n\n'
        'Todo lo puedo en Cristo que me fortalece.\n\n'
        'Descubre Verbum y comparte la Palabra:\n\n'
        'https://play.google.com/store/apps/details?id=com.ozcorp.verbum',
      );
      expect(gateway.sharedText, contains(ShareMessageBuilder.playStoreUrl));
      expect(gateway.sharedFilesExisted, isTrue);
      expect(gateway.sharedFileBytes, [png1, png2, png3]);
      expect(gateway.deletedPaths, unorderedEquals(gateway.sharedPaths));
    },
  );

  test(
    'dismissed native share returns dismissed and cleans every file',
    () async {
      gateway.shareStatus = NativeShareStatus.dismissed;

      final result = await coordinator.share(
        content: content,
        renderPages: () async => [
          Uint8List.fromList(png1),
          Uint8List.fromList(png2),
        ],
      );

      expect(result, ShareExportResult.dismissed);
      expect(gateway.deletedPaths, unorderedEquals(gateway.sharedPaths));
      for (final path in gateway.sharedPaths) {
        expect(await File(path).exists(), isFalse);
      }
    },
  );

  test(
    'renderer failure shares no partial set and becomes a render failure',
    () async {
      var renderedPages = 0;

      final future = coordinator.share(
        content: content,
        renderPages: () async {
          renderedPages++;
          final firstPage = Uint8List.fromList(png1);
          expect(firstPage, isNotEmpty);
          renderedPages++;
          throw StateError('page 2 did not render');
        },
      );

      await expectLater(
        future,
        throwsA(
          isA<ShareExportFailure>()
              .having(
                (failure) => failure.stage,
                'stage',
                ShareExportStage.render,
              )
              .having(
                (failure) => failure.userMessage,
                'userMessage',
                'No pudimos crear la tarjeta.',
              ),
        ),
      );
      expect(renderedPages, 2);
      expect(gateway.sharedPaths, isEmpty);
      expect(gateway.savedPaths, isEmpty);
    },
  );

  test(
    'save sends every complete page to the gallery and then cleans it',
    () async {
      final result = await coordinator.save(
        content: content,
        renderPages: () async => [
          Uint8List.fromList(png1),
          Uint8List.fromList(png2),
          Uint8List.fromList(png3),
        ],
      );

      expect(result, ShareExportResult.saved);
      expect(gateway.savedPaths, hasLength(3));
      expect(gateway.savedFilesExisted, everyElement(isTrue));
      expect(gateway.savedFileBytes, [png1, png2, png3]);
      expect(gateway.deletedPaths, unorderedEquals(gateway.savedPaths));
    },
  );

  test(
    'copy puts title, reference, body, and Play Store link on clipboard',
    () async {
      await coordinator.copy(content);

      expect(gateway.copiedText, ShareMessageBuilder.build(content));
      expect(gateway.copiedText, contains('Palabra del día'));
      expect(gateway.copiedText, contains('Filipenses 4:13'));
      expect(
        gateway.copiedText,
        contains('Todo lo puedo en Cristo que me fortalece.'),
      );
      expect(gateway.copiedText, contains(ShareMessageBuilder.playStoreUrl));
    },
  );

  test('temporary file names are unique within and across exports', () async {
    await coordinator.share(
      content: content,
      renderPages: () async => [
        Uint8List.fromList(png1),
        Uint8List.fromList(png2),
        Uint8List.fromList(png3),
      ],
    );
    final firstExportPaths = List<String>.of(gateway.sharedPaths);
    gateway.sharedPaths.clear();

    await coordinator.share(
      content: content,
      renderPages: () async => [
        Uint8List.fromList(png1),
        Uint8List.fromList(png2),
        Uint8List.fromList(png3),
      ],
    );

    final allPaths = [...firstExportPaths, ...gateway.sharedPaths];
    expect(allPaths.toSet(), hasLength(allPaths.length));
    expect(allPaths, everyElement(endsWith('.png')));
  });

  test(
    'share exception is typed and still cleans every temporary file',
    () async {
      gateway.shareError = StateError('native share failed');

      final future = coordinator.share(
        content: content,
        renderPages: () async => [
          Uint8List.fromList(png1),
          Uint8List.fromList(png2),
        ],
      );

      await expectLater(
        future,
        throwsA(
          isA<ShareExportFailure>()
              .having(
                (failure) => failure.stage,
                'stage',
                ShareExportStage.share,
              )
              .having(
                (failure) => failure.cause,
                'cause',
                same(gateway.shareError),
              ),
        ),
      );
      expect(gateway.deletedPaths, unorderedEquals(gateway.sharedPaths));
    },
  );

  test('cleanup failure does not replace a successful share result', () async {
    gateway.deleteErrorAtCall = 1;

    final result = await coordinator.share(
      content: content,
      renderPages: () async => [
        Uint8List.fromList(png1),
        Uint8List.fromList(png2),
      ],
    );

    expect(result, ShareExportResult.shared);
    expect(gateway.deleteAttempts, 2);
  });

  test('cleanup failure does not replace the primary share failure', () async {
    gateway.shareError = StateError('native share failed');
    gateway.deleteErrorAtCall = 1;

    final future = coordinator.share(
      content: content,
      renderPages: () async => [
        Uint8List.fromList(png1),
        Uint8List.fromList(png2),
      ],
    );

    await expectLater(
      future,
      throwsA(
        isA<ShareExportFailure>()
            .having((failure) => failure.stage, 'stage', ShareExportStage.share)
            .having(
              (failure) => failure.cause,
              'cause',
              same(gateway.shareError),
            ),
      ),
    );
    expect(gateway.deleteAttempts, 2);
  });

  test(
    'unavailable native share becomes an end-user-safe share failure',
    () async {
      gateway.shareStatus = NativeShareStatus.unavailable;

      final future = coordinator.share(
        content: content,
        renderPages: () async => [Uint8List.fromList(png1)],
      );

      await expectLater(
        future,
        throwsA(
          isA<ShareExportFailure>()
              .having(
                (failure) => failure.stage,
                'stage',
                ShareExportStage.share,
              )
              .having(
                (failure) => failure.userMessage,
                'userMessage',
                isNot(contains('unavailable')),
              ),
        ),
      );
    },
  );
}

final class FakeSharePlatformGateway implements SharePlatformGateway {
  FakeSharePlatformGateway(this.directory);

  final Directory directory;
  final List<String> sharedPaths = [];
  final List<String> savedPaths = [];
  final List<String> deletedPaths = [];
  final List<List<int>> sharedFileBytes = [];
  final List<List<int>> savedFileBytes = [];
  final List<bool> savedFilesExisted = [];

  NativeShareStatus shareStatus = NativeShareStatus.success;
  Object? shareError;
  int? deleteErrorAtCall;
  int deleteAttempts = 0;
  String? sharedText;
  String? copiedText;
  bool sharedFilesExisted = false;

  @override
  Future<void> copyText(String text) async {
    copiedText = text;
  }

  @override
  Future<void> deleteFile(String path) async {
    deleteAttempts++;
    if (deleteAttempts == deleteErrorAtCall) {
      throw FileSystemException('simulated cleanup failure', path);
    }
    deletedPaths.add(path);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> saveImage(String path) async {
    savedPaths.add(path);
    final file = File(path);
    savedFilesExisted.add(await file.exists());
    savedFileBytes.add(await file.readAsBytes());
  }

  @override
  Future<NativeShareStatus> shareFiles(List<String> paths, String text) async {
    sharedPaths.addAll(paths);
    sharedText = text;
    sharedFilesExisted = await Future.wait(
      paths.map((path) => File(path).exists()),
    ).then((results) => results.every((exists) => exists));
    sharedFileBytes.addAll(
      await Future.wait(paths.map((path) => File(path).readAsBytes())),
    );
    if (shareError case final error?) {
      throw error;
    }
    return shareStatus;
  }

  @override
  Future<NativeShareStatus> shareText(String text) async {
    sharedText = text;
    if (shareError case final error?) {
      throw error;
    }
    return shareStatus;
  }

  @override
  Future<Directory> temporaryDirectory() async => directory;
}
