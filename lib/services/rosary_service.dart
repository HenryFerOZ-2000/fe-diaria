import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/rosary_guide.dart';

/// Servicio para manejar la guía del rosario
class RosaryService {
  RosaryGuide? _guide;
  bool _loaded = false;

  /// Carga la guía del rosario desde el archivo JSON
  Future<void> loadGuide() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/rosary_guide.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _guide = RosaryGuide.fromJson(jsonData);
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading rosary guide: $e');
      _guide = null;
    }
  }

  /// Obtiene la guía completa del rosario
  RosaryGuide? getGuide() {
    return _guide;
  }

  /// Obtiene los misterios del día actual
  RosaryMystery? getTodayMysteries() {
    if (_guide == null) return null;

    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday

    // Lunes y Sábado: Gozosos
    if (dayOfWeek == 1 || dayOfWeek == 6) {
      return _guide!.mysteries.firstWhere((m) => m.id == 'joyful');
    }
    // Martes y Viernes: Dolorosos
    else if (dayOfWeek == 2 || dayOfWeek == 5) {
      return _guide!.mysteries.firstWhere((m) => m.id == 'sorrowful');
    }
    // Miércoles y Domingo: Gloriosos
    else if (dayOfWeek == 3 || dayOfWeek == 7) {
      return _guide!.mysteries.firstWhere((m) => m.id == 'glorious');
    }
    // Jueves: Luminosos
    else if (dayOfWeek == 4) {
      return _guide!.mysteries.firstWhere((m) => m.id == 'luminous');
    }

    return _guide!.mysteries.first;
  }

  /// Obtiene todos los misterios
  List<RosaryMystery> getAllMysteries() {
    if (_guide == null) return [];
    return List.unmodifiable(_guide!.mysteries);
  }

  /// Obtiene todos los pasos del rosario
  List<RosaryStep> getAllSteps() {
    if (_guide == null) return [];
    return List.unmodifiable(_guide!.steps);
  }
}

