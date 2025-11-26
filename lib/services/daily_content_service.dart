import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio unificado para gestionar contenido diario (versículos y oraciones)
/// Basado en día del año (1-365) sin dependencia de meses o fechas exactas
class DailyContentService {
  static final DailyContentService _instance = DailyContentService._internal();
  factory DailyContentService() => _instance;
  DailyContentService._internal();

  List<Map<String, dynamic>>? _verses;
  List<String>? _morningPrayers;
  List<String>? _nightPrayers;
  bool _isLoading = false;

  /// Obtiene el día del año (1-365) basado en la fecha actual
  int getDayOfYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(start).inDays + 1;
    return dayOfYear; // Retorna 1-365 (o 366 en años bisiestos)
  }

  /// Carga el contenido desde los archivos JSON unificados
  Future<void> loadContent() async {
    if (_isLoading) return;
    if (_verses != null && _morningPrayers != null && _nightPrayers != null) return;

    _isLoading = true;
    try {
      // Cargar versículos (estructura: array de objetos con id, text, reference, etc.)
      final versesJson = await rootBundle.loadString('assets/data/verses.json');
      final List<dynamic> versesData = json.decode(versesJson);
      _verses = versesData.map((e) => e as Map<String, dynamic>).toList();

      // Cargar oraciones de la mañana
      final morningJson = await rootBundle.loadString('assets/data/morning_prayers.json');
      final List<dynamic> morningData = json.decode(morningJson);
      _morningPrayers = morningData.map((e) => e as String).toList();

      // Cargar oraciones de la noche
      final nightJson = await rootBundle.loadString('assets/data/night_prayers.json');
      final List<dynamic> nightData = json.decode(nightJson);
      _nightPrayers = nightData.map((e) => e as String).toList();

      debugPrint('✓ Contenido cargado: ${_verses!.length} versículos, ${_morningPrayers!.length} oraciones mañana, ${_nightPrayers!.length} oraciones noche');
    } catch (e) {
      debugPrint('Error cargando contenido: $e');
      _verses = [];
      _morningPrayers = [];
      _nightPrayers = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Obtiene el versículo del día usando día del año (retorna solo el texto)
  String getTodayVerse() {
    if (_verses == null || _verses!.isEmpty) {
      throw Exception('No hay versículos disponibles. Llama a loadContent() primero.');
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos versículos que días
    final index = (dayOfYear - 1) % _verses!.length;
    
    return _verses![index]['text'] as String;
  }

  /// Obtiene el versículo completo del día (con id, reference, etc.) como Map
  Map<String, dynamic> getTodayVerseData() {
    if (_verses == null || _verses!.isEmpty) {
      throw Exception('No hay versículos disponibles. Llama a loadContent() primero.');
    }

    final dayOfYear = getDayOfYear();
    final index = (dayOfYear - 1) % _verses!.length;
    
    return _verses![index];
  }

  /// Obtiene la oración de la mañana del día usando día del año
  String getMorningPrayer() {
    if (_morningPrayers == null || _morningPrayers!.isEmpty) {
      throw Exception('No hay oraciones de la mañana disponibles. Llama a loadContent() primero.');
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos oraciones que días
    final index = (dayOfYear - 1) % _morningPrayers!.length;
    
    return _morningPrayers![index];
  }

  /// Obtiene la oración de la noche del día usando día del año
  String getNightPrayer() {
    if (_nightPrayers == null || _nightPrayers!.isEmpty) {
      throw Exception('No hay oraciones de la noche disponibles. Llama a loadContent() primero.');
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos oraciones que días
    final index = (dayOfYear - 1) % _nightPrayers!.length;
    
    return _nightPrayers![index];
  }

  /// Obtiene todos los versículos como lista de Maps
  List<Map<String, dynamic>> getAllVersesData() {
    if (_verses == null) {
      throw Exception('No hay versículos disponibles. Llama a loadContent() primero.');
    }
    return _verses!;
  }

  /// Limpia el caché y fuerza recarga
  void clearCache() {
    _verses = null;
    _morningPrayers = null;
    _nightPrayers = null;
    _isLoading = false;
  }
}

