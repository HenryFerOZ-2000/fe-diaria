import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/prayer.dart';
import '../models/verse.dart';

enum WidgetPinRequestResult { requested, unsupported, failed }

/// Puente con el widget nativo de Android.
///
/// El contenido se resuelve en Android para que el widget funcione aunque
/// Flutter no se haya abierto. Los métodos estáticos conservan compatibilidad
/// con los puntos de llamada existentes mientras la UI usa la instancia.
class WidgetService {
  WidgetService._(this._channel, this._isAndroid);

  static final WidgetService _instance = WidgetService._(
    const MethodChannel('com.ozcorp.verbum/widget'),
    defaultTargetPlatform == TargetPlatform.android,
  );

  factory WidgetService() => _instance;

  @visibleForTesting
  factory WidgetService.forTesting({
    required MethodChannel channel,
    required bool isAndroid,
  }) => WidgetService._(channel, isAndroid);

  final MethodChannel _channel;
  final bool _isAndroid;

  Future<bool> refreshWidget() => _invokeBool('refreshWidget');

  Future<bool> hasWidgets() => _invokeBool('hasWidgets');

  Future<bool> isPinningSupported() => _invokeBool('isPinWidgetSupported');

  Future<WidgetPinRequestResult> requestPinWidget() async {
    if (!await isPinningSupported()) {
      return WidgetPinRequestResult.unsupported;
    }
    try {
      final requested =
          await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
      return requested
          ? WidgetPinRequestResult.requested
          : WidgetPinRequestResult.failed;
    } on PlatformException {
      return WidgetPinRequestResult.failed;
    } on MissingPluginException {
      return WidgetPinRequestResult.failed;
    }
  }

  Future<bool> _invokeBool(String method) async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> initialize() async {
    await _instance.refreshWidget();
  }

  /// Conserva la API usada por la app; Android ya no depende de este contenido.
  static Future<void> updateWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) async {
    await _instance.refreshWidget();
  }

  static Future<void> updateHomeScreenWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) => updateWidget(
    verse: verse,
    morningPrayer: morningPrayer,
    eveningPrayer: eveningPrayer,
  );

  static Future<void> updateLockScreenWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) => updateWidget(
    verse: verse,
    morningPrayer: morningPrayer,
    eveningPrayer: eveningPrayer,
  );
}
