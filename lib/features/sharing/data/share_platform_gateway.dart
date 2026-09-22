import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum NativeShareStatus { success, dismissed, unavailable }

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
  Future<void> saveImage(String path) => Gal.putImage(path);

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
