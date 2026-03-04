import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiService {
  static SystemUiOverlayStyle overlayForBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static void applyForBrightness(Brightness brightness) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayForBrightness(brightness));
  }

  static void applyFromContext(BuildContext context) {
    applyForBrightness(Theme.of(context).brightness);
  }

  static void applyFromPlatformBrightness() {
    applyForBrightness(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }
}