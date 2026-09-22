import 'package:flutter/material.dart';

import '../features/sharing/application/share_export_coordinator.dart';
import '../features/sharing/application/share_message_builder.dart';
import '../features/sharing/data/share_platform_gateway.dart';
import '../features/sharing/domain/share_content.dart';
import '../features/sharing/presentation/share_composer_screen.dart';

abstract final class ShareService {
  static Future<void> openComposer(
    BuildContext context,
    ShareContent content,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ShareComposerScreen(
        content: content,
        coordinator: const ShareExportCoordinator(SystemSharePlatformGateway()),
      ),
    ),
  );

  static Future<NativeShareStatus> shareTextFallback(ShareContent content) =>
      const SystemSharePlatformGateway().shareText(
        ShareMessageBuilder.build(content),
      );
}
