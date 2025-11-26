import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/verse.dart';
import '../models/prayer.dart';

/// Servicio nativo para gestionar widgets de Android sin dependencias externas
/// Usa MethodChannel para comunicación con código nativo
class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.ozcorp.versiculo_de_hoy/widget');
  static bool _initialized = false;

  /// Inicializa el servicio de widgets
  static Future<void> initialize() async {
    try {
      // Verificar si la plataforma soporta widgets (Android)
      if (defaultTargetPlatform == TargetPlatform.android) {
        _initialized = true;
        debugPrint('Widget service initialized successfully');
      } else {
        debugPrint('Widget service only available on Android');
      }
    } catch (e) {
      // Los widgets pueden no estar disponibles en todos los dispositivos
      debugPrint('Error initializing widget service: $e');
      _initialized = false;
    }
  }

  /// Actualiza el widget con el versículo actual
  /// También puede incluir información de oraciones si está disponible
  static Future<void> updateWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) async {
    if (!_initialized) {
      debugPrint('Widget service not initialized');
      return;
    }

    try {
      // Priorizar el versículo para el widget principal
      if (verse != null) {
        final result = await _channel.invokeMethod<bool>('updateWidget', {
          'verseText': verse.text,
          'verseReference': verse.reference,
        });

        if (result == true) {
          debugPrint('Widget updated successfully');
        } else {
          debugPrint('Widget update returned false');
        }
      } else {
        debugPrint('No verse data to update widget');
      }
    } catch (e) {
      // Los widgets pueden no estar disponibles en todos los dispositivos
      // No es crítico si falla - la app sigue funcionando
      debugPrint('Error updating widget: $e');
    }
  }

  /// Actualiza el widget de la pantalla de inicio
  /// Alias para updateWidget para mantener compatibilidad
  static Future<void> updateHomeScreenWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) async {
    await updateWidget(
      verse: verse,
      morningPrayer: morningPrayer,
      eveningPrayer: eveningPrayer,
    );
  }

  /// Actualiza el widget de la pantalla de bloqueo
  /// Por ahora usa la misma implementación que el widget de inicio
  static Future<void> updateLockScreenWidget({
    Verse? verse,
    Prayer? morningPrayer,
    Prayer? eveningPrayer,
  }) async {
    // En Android, el widget de bloqueo requiere configuración adicional
    // Por ahora, actualizamos el widget de inicio
    await updateWidget(
      verse: verse,
      morningPrayer: morningPrayer,
      eveningPrayer: eveningPrayer,
    );
  }
}

