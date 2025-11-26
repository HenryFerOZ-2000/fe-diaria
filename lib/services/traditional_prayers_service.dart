import 'dart:convert';
import 'package:flutter/services.dart';

/// Servicio para gestionar las oraciones tradicionales
class TraditionalPrayersService {
  static final TraditionalPrayersService _instance = TraditionalPrayersService._internal();
  factory TraditionalPrayersService() => _instance;
  TraditionalPrayersService._internal();

  Map<String, dynamic>? _prayersData;

  /// Carga las oraciones desde el archivo JSON
  Future<void> loadPrayers() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/oraciones/oraciones.json');
      _prayersData = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading traditional prayers: $e');
    }
  }

  /// Obtiene las categorías disponibles para una religión
  List<String> getCategories(String religion) {
    if (_prayersData == null) return [];
    final religionData = _prayersData![religion] as Map<String, dynamic>?;
    if (religionData == null) return [];
    return religionData.keys.toList();
  }

  /// Obtiene las oraciones de una categoría específica
  Map<String, dynamic> getPrayersByCategory(String religion, String category) {
    if (_prayersData == null) return {};
    final religionData = _prayersData![religion] as Map<String, dynamic>?;
    if (religionData == null) return {};
    final categoryData = religionData[category] as Map<String, dynamic>?;
    if (categoryData == null) return {};
    return categoryData;
  }

  /// Obtiene una oración específica
  Map<String, dynamic>? getPrayer(String religion, String category, String prayerKey) {
    final categoryPrayers = getPrayersByCategory(religion, category);
    return categoryPrayers[prayerKey] as Map<String, dynamic>?;
  }

  /// Obtiene el nombre de la categoría en formato legible
  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'basicas':
        return 'Oraciones Básicas';
      case 'arcangeles':
        return 'Arcángeles';
      case 'del_dia':
        return 'Oraciones del Día';
      case 'biblicas':
        return 'Oraciones Bíblicas';
      case 'promesas':
        return 'Promesas Bíblicas';
      case 'otras':
        return 'Otras Oraciones';
      default:
        return category;
    }
  }

  /// Obtiene los pasos de un día específico de la Novena
  Map<String, dynamic>? getNovenaDay(int day) {
    if (_prayersData == null) return null;
    final novenaData = _prayersData!['novena'] as Map<String, dynamic>?;
    if (novenaData == null) return null;
    final dayKey = 'dia_$day';
    return novenaData[dayKey] as Map<String, dynamic>?;
  }

  /// Obtiene un paso específico de un día de la Novena
  Map<String, dynamic>? getNovenaStep(int day, int step) {
    final dayData = getNovenaDay(day);
    if (dayData == null) return null;
    final stepKey = 'paso_$step';
    return dayData[stepKey] as Map<String, dynamic>?;
  }

  /// Obtiene el número total de pasos de un día de la Novena
  int getNovenaDayStepCount(int day) {
    final dayData = getNovenaDay(day);
    if (dayData == null) return 0;
    return dayData.length;
  }
}

