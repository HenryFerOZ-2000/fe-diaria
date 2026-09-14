import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'tradition_texts.dart';

class TraditionGuard {
  TraditionGuard._();

  /// Devuelve true cuando bloquea un módulo exclusivo católico en tradición evangélica.
  static bool blockCatholicOnlyModuleIfNeeded({
    required BuildContext context,
    required String moduleName,
    required bool Function() isMounted,
  }) {
    if (!StorageService().isEvangelicalTradition) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TraditionTexts.catholicOnlyModuleMessage(moduleName)),
          duration: const Duration(seconds: 2),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });

    return true;
  }
}
