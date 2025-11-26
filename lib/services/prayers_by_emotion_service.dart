import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar oraciones por emoción
class PrayersByEmotionService {
  List<Map<String, dynamic>> _prayers = [];
  bool _loaded = false;

  /// Carga las oraciones desde el archivo JSON
  Future<void> loadPrayers() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/prayers_by_emotion.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _prayers = jsonList.cast<Map<String, dynamic>>();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading prayers by emotion: $e');
      _prayers = [];
    }
  }

  /// Obtiene una oración para una emoción específica
  Map<String, dynamic>? getPrayerForEmotion(String emotion) {
    try {
      return _prayers.firstWhere(
        (p) => (p['emotion'] as String).toLowerCase() == emotion.toLowerCase(),
        orElse: () => _prayers.first,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las oraciones
  List<Map<String, dynamic>> getAllPrayers() {
    return List.unmodifiable(_prayers);
  }

  /// Obtiene todas las emociones disponibles
  List<String> getAvailableEmotions() {
    return _prayers.map((p) => p['emotion'] as String).toSet().toList();
  }
}

