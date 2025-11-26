import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar santos del día
class SaintsService {
  List<Map<String, dynamic>> _saints = [];
  bool _loaded = false;

  /// Carga los santos desde el archivo JSON
  Future<void> loadSaints() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/saints.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _saints = jsonList.cast<Map<String, dynamic>>();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading saints: $e');
      _saints = [];
    }
  }

  /// Obtiene todos los santos
  List<Map<String, dynamic>> getAllSaints() {
    return List.unmodifiable(_saints);
  }

  /// Obtiene un santo por ID
  Map<String, dynamic>? getSaintById(int id) {
    try {
      return _saints.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene santos por tags
  List<Map<String, dynamic>> getSaintsByTags(List<String> tags) {
    return _saints.where((s) {
      final saintTags = s['tags'] as List<dynamic>?;
      if (saintTags == null) return false;
      return tags.any((tag) => saintTags.contains(tag));
    }).toList();
  }
}

