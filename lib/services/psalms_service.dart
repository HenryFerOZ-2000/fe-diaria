import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/psalm.dart';

/// Servicio para manejar salmos por categoría
class PsalmsService {
  List<Psalm> _psalms = [];
  bool _loaded = false;

  /// Carga los salmos desde el archivo JSON
  Future<void> loadPsalms() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/psalms.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _psalms = jsonList.map((json) => Psalm.fromJson(json as Map<String, dynamic>)).toList();
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading psalms: $e');
      _psalms = [];
    }
  }

  /// Obtiene todos los salmos
  List<Psalm> getAllPsalms() {
    return List.unmodifiable(_psalms);
  }

  /// Obtiene salmos por categoría
  List<Psalm> getPsalmsByCategory(String category) {
    return _psalms.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Obtiene todas las categorías disponibles
  List<String> getCategories() {
    final categories = _psalms.map((p) => p.category).toSet().toList();
    return categories;
  }

  /// Obtiene un salmo por ID
  Psalm? getPsalmById(int id) {
    try {
      return _psalms.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene salmos por tags
  List<Psalm> getPsalmsByTags(List<String> tags) {
    return _psalms.where((p) {
      if (p.tags == null) return false;
      return tags.any((tag) => p.tags!.contains(tag));
    }).toList();
  }
}

