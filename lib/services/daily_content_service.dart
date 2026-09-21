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
  List<String>? _familyPrayers;
  List<String>? _morningPrayersEvangelical;
  List<String>? _nightPrayersEvangelical;
  Future<void>? _loading;

  /// Obtiene el día del año (1-365) basado en la fecha actual
  int getDayOfYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(start).inDays + 1;
    return dayOfYear; // Retorna 1-365 (o 366 en años bisiestos)
  }

  /// Carga el contenido desde los archivos JSON unificados
  Future<void> loadContent() {
    if (_loading != null) return _loading!;
    if (_verses != null &&
        _morningPrayers != null &&
        _nightPrayers != null &&
        _morningPrayersEvangelical != null &&
        _nightPrayersEvangelical != null &&
        _familyPrayers != null) {
      return Future.value();
    }
    return _loading = _loadContent().whenComplete(() => _loading = null);
  }

  Future<void> _loadContent() async {
    try {
      // Cargar versículos (estructura: array de objetos con id, text, reference, etc.)
      final versesJson = await rootBundle.loadString('assets/data/verses.json');
      final List<dynamic> versesData = json.decode(versesJson);
      final verses = versesData.map((e) => e as Map<String, dynamic>).toList();

      // Cargar oraciones de la mañana
      final morningJson = await rootBundle.loadString(
        'assets/data/morning_prayers.json',
      );
      final List<dynamic> morningData = json.decode(morningJson);
      final morningPrayers = morningData.map((e) => e as String).toList();

      // No sustituir una tradición por otra si falla su catálogo.
      final morningEvangelicalJson = await rootBundle.loadString(
        'assets/traditions/evangelical/morning_prayers.json',
      );
      final List<dynamic> morningEvangelicalData = json.decode(
        morningEvangelicalJson,
      );
      final morningPrayersEvangelical = morningEvangelicalData
          .map((e) => e as String)
          .toList();

      // Cargar oraciones de la noche (estructura: array de objetos con campo "text")
      final nightJson = await rootBundle.loadString(
        'assets/data/night_prayers.json',
      );
      final List<dynamic> nightData = json.decode(nightJson);
      final nightPrayers = nightData
          .map((e) => (e as Map<String, dynamic>)['text'] as String)
          .toList();

      // Cada tradición tiene un recurso empaquetado explícito.
      final nightEvangelicalJson = await rootBundle.loadString(
        'assets/traditions/evangelical/night_prayers.json',
      );
      final List<dynamic> nightEvangelicalData = json.decode(
        nightEvangelicalJson,
      );
      final nightPrayersEvangelical = nightEvangelicalData
          .map((e) => (e as Map<String, dynamic>)['text'] as String)
          .toList();

      // Cargar oraciones por intención y filtrar las de familia
      final intentionJson = await rootBundle.loadString(
        'assets/data/prayers_by_intention.json',
      );
      final List<dynamic> intentionData = json.decode(intentionJson);
      final familyPrayers = intentionData
          .where((e) {
            final intention = (e['intention'] as String?)?.toLowerCase() ?? '';
            final tags = (e['tags'] as List<dynamic>?)
                ?.map((t) => (t as String).toLowerCase())
                .toList();
            return intention == 'familia' ||
                intention == 'hijos' ||
                intention == 'relaciones' ||
                (tags != null && tags.contains('familia'));
          })
          .map((e) => e['text'] as String)
          .toList();

      // Publish a complete snapshot only after every resource is loaded.
      _verses = verses;
      _morningPrayers = morningPrayers;
      _nightPrayers = nightPrayers;
      _morningPrayersEvangelical = morningPrayersEvangelical;
      _nightPrayersEvangelical = nightPrayersEvangelical;
      _familyPrayers = familyPrayers;
      debugPrint(
        '✓ Contenido cargado: ${_verses!.length} versículos, ${_morningPrayers!.length} oraciones mañana, ${_nightPrayers!.length} oraciones noche',
      );
    } catch (e) {
      debugPrint('Error cargando contenido: $e');
      clearCache();
      rethrow;
    }
  }

  /// Obtiene el versículo del día usando día del año (retorna solo el texto)
  String getTodayVerse() {
    if (_verses == null || _verses!.isEmpty) {
      throw Exception(
        'No hay versículos disponibles. Llama a loadContent() primero.',
      );
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos versículos que días
    final index = (dayOfYear - 1) % _verses!.length;

    return _verses![index]['text'] as String;
  }

  /// Obtiene el versículo completo del día (con id, reference, etc.) como Map
  Map<String, dynamic> getTodayVerseData() {
    if (_verses == null || _verses!.isEmpty) {
      throw Exception(
        'No hay versículos disponibles. Llama a loadContent() primero.',
      );
    }

    final dayOfYear = getDayOfYear();
    final index = (dayOfYear - 1) % _verses!.length;

    return _verses![index];
  }

  /// Obtiene la oración de la mañana del día usando día del año
  String getMorningPrayer({String tradition = 'catolica'}) {
    final source = tradition == 'cristiana' || tradition == 'general'
        ? _morningPrayersEvangelical
        : _morningPrayers;
    if (source == null || source.isEmpty) {
      throw Exception(
        'No hay oraciones de la mañana disponibles. Llama a loadContent() primero.',
      );
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos oraciones que días
    final index = (dayOfYear - 1) % source.length;

    return source[index];
  }

  /// Obtiene la oración de la noche del día usando día del año
  String getNightPrayer({String tradition = 'catolica'}) {
    final source = tradition == 'cristiana' || tradition == 'general'
        ? _nightPrayersEvangelical
        : _nightPrayers;
    if (source == null || source.isEmpty) {
      throw Exception(
        'No hay oraciones de la noche disponibles. Llama a loadContent() primero.',
      );
    }

    final dayOfYear = getDayOfYear();
    // Usar módulo para evitar errores si hay más o menos oraciones que días
    final index = (dayOfYear - 1) % source.length;

    return source[index];
  }

  /// Obtiene todos los versículos como lista de Maps
  List<Map<String, dynamic>> getAllVersesData() {
    if (_verses == null) {
      throw Exception(
        'No hay versículos disponibles. Llama a loadContent() primero.',
      );
    }
    return _verses!;
  }

  /// Obtiene una oración diaria para familia (familia/hijos/relaciones) usando día del año
  String getFamilyPrayer() {
    if (_familyPrayers == null || _familyPrayers!.isEmpty) {
      throw Exception(
        'No hay oraciones para la familia disponibles. Llama a loadContent() primero.',
      );
    }

    final dayOfYear = getDayOfYear();
    final index = (dayOfYear - 1) % _familyPrayers!.length;

    return _familyPrayers![index];
  }

  /// Limpia el caché y fuerza recarga
  void clearCache() {
    _verses = null;
    _morningPrayers = null;
    _nightPrayers = null;
    _familyPrayers = null;
    _morningPrayersEvangelical = null;
    _nightPrayersEvangelical = null;
  }
}
