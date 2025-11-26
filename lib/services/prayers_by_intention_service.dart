import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar oraciones por intención
class PrayersByIntentionService {
  List<Map<String, dynamic>> _prayers = [];
  bool _loaded = false;

  /// Carga las oraciones desde el archivo JSON
  Future<void> loadPrayers() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/prayers_by_intention.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _prayers = jsonList.cast<Map<String, dynamic>>();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading prayers by intention: $e');
      _prayers = [];
    }
  }

  /// Obtiene una oración para una intención específica
  Map<String, dynamic>? getPrayerForIntention(String intention) {
    try {
      return _prayers.firstWhere(
        (p) => (p['intention'] as String).toLowerCase() == intention.toLowerCase(),
        orElse: () => _prayers.first,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las intenciones disponibles
  List<String> getAvailableIntentions() {
    return _prayers.map((p) => p['intention'] as String).toSet().toList();
  }

  /// Obtiene todas las oraciones
  List<Map<String, dynamic>> getAllPrayers() {
    return List.unmodifiable(_prayers);
  }
}

