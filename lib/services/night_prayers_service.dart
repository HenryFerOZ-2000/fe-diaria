import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar oraciones para dormir
class NightPrayersService {
  List<Map<String, dynamic>> _prayers = [];
  bool _loaded = false;

  /// Carga las oraciones desde el archivo JSON
  Future<void> loadPrayers() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/night_prayers.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _prayers = jsonList.cast<Map<String, dynamic>>();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading night prayers: $e');
      _prayers = [];
    }
  }

  /// Obtiene todas las oraciones
  List<Map<String, dynamic>> getAllPrayers() {
    return List.unmodifiable(_prayers);
  }

  /// Obtiene una oración aleatoria
  Map<String, dynamic>? getRandomPrayer() {
    if (_prayers.isEmpty) return null;
    _prayers.shuffle();
    return _prayers.first;
  }

  /// Obtiene una oración por ID
  Map<String, dynamic>? getPrayerById(int id) {
    try {
      return _prayers.firstWhere((p) => p['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene oraciones por tags
  List<Map<String, dynamic>> getPrayersByTags(List<String> tags) {
    return _prayers.where((p) {
      final prayerTags = p['tags'] as List<dynamic>?;
      if (prayerTags == null) return false;
      return tags.any((tag) => prayerTags.contains(tag));
    }).toList();
  }
}

