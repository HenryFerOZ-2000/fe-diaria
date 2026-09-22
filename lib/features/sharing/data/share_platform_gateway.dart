import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum NativeShareStatus { success, dismissed, unavailable }

enum GallerySaveFailureReason {
  accessDenied,
  insufficientSpace,
  unsupportedFormat,
  unknown,
}

/// Keeps plugin-specific diagnostics behind the platform boundary.
final class GallerySaveFailure implements Exception {
  const GallerySaveFailure(this.reason, this.cause);

  final GallerySaveFailureReason reason;
  final Object cause;
}

abstract interface class SharePlatformGateway {
  Future<Directory> temporaryDirectory();

  Future<NativeShareStatus> shareFiles(List<String> paths, String text);

  Future<NativeShareStatus> shareText(String text);

  Future<void> saveImage(String path);

  Future<void> copyText(String text);

  Future<void> deleteFile(String path);
}

final class SystemSharePlatformGateway implements SharePlatformGateway {
  const SystemSharePlatformGateway();

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<void> deleteFile(String path) => File(path).delete();

  @override
  Future<void> saveImage(String path) async {
    try {
      await Gal.putImage(path);
    } on GalException catch (error, stackTrace) {
      final reason = switch (error.type) {
        GalExceptionType.accessDenied => GallerySaveFailureReason.accessDenied,
        GalExceptionType.notEnoughSpace =>
          GallerySaveFailureReason.insufficientSpace,
        GalExceptionType.notSupportedFormat =>
          GallerySaveFailureReason.unsupportedFormat,
        GalExceptionType.unexpected => GallerySaveFailureReason.unknown,
      };
      Error.throwWithStackTrace(GallerySaveFailure(reason, error), stackTrace);
    }
  }

  @override
  Future<NativeShareStatus> shareFiles(List<String> paths, String text) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: paths.map(XFile.new).toList(growable: false),
        text: text,
        subject: 'Verbum',
        title: 'Compartir desde Verbum',
      ),
    );
    return _mapShareStatus(result.status);
  }

  @override
  Future<NativeShareStatus> shareText(String text) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Verbum',
        title: 'Compartir desde Verbum',
      ),
    );
    return _mapShareStatus(result.status);
  }

  @override
  Future<Directory> temporaryDirectory() => getTemporaryDirectory();

  NativeShareStatus _mapShareStatus(ShareResultStatus status) =>
      switch (status) {
        ShareResultStatus.success => NativeShareStatus.success,
        ShareResultStatus.dismissed => NativeShareStatus.dismissed,
        ShareResultStatus.unavailable => NativeShareStatus.unavailable,
      };
}
