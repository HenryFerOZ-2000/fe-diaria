import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/devotional.dart';

/// Servicio para manejar devocionales diarios
class DevotionalsService {
  List<Devotional> _devotionals = [];
  bool _loaded = false;

  /// Carga los devocionales desde el archivo JSON
  Future<void> loadDevotionals() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/devotionals.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _devotionals = jsonList.map((json) => Devotional.fromJson(json as Map<String, dynamic>)).toList();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading devotionals: $e');
      _devotionals = [];
    }
  }

  /// Obtiene todos los devocionales
  List<Devotional> getAllDevotionals() {
    return List.unmodifiable(_devotionals);
  }

  /// Obtiene un devocional por ID
  Devotional? getDevotionalById(int id) {
    try {
      return _devotionals.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el devocional del día (basado en la fecha)
  Devotional? getTodayDevotional() {
    if (_devotionals.isEmpty) return null;
    
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final index = dayOfYear % _devotionals.length;
    
    return _devotionals[index];
  }

  /// Obtiene devocionales por tags
  List<Devotional> getDevotionalsByTags(List<String> tags) {
    return _devotionals.where((d) {
      if (d.tags == null) return false;
      return tags.any((tag) => d.tags!.contains(tag));
    }).toList();
  }
}

