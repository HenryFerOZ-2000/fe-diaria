import 'package:flutter/foundation.dart';
import '../models/verse.dart';
import 'cache_service.dart';
import '../bible/services/daily_verse_service.dart' as offline_daily;

/// Servicio para gestionar versículos bíblicos
/// Integra API externa con caché local y fallback
/// Usa el nuevo sistema basado en día del año
class VerseService {
  static final VerseService _instance = VerseService._internal();
  factory VerseService() => _instance;
  VerseService._internal();

  DateTime? _lastDate;
  Verse? _todayVerse;

  /// (Legacy) Carga versículos locales - ahora se usa RV1909 offline.
  Future<List<Verse>> loadLocalVerses() async {
    return [];
  }

  /// Obtiene el versículo del día
  /// Prioridad: Local (español) → Caché del día → Caché anterior → API (último recurso)
  /// Usa el nuevo sistema basado en día del año (1-365)
  Future<Verse> getTodayVerse() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Si ya tenemos el versículo de hoy en memoria, retornarlo
    if (_lastDate != null &&
        _todayVerse != null &&
        _lastDate!.isAtSameMomentAs(today)) {
      return _todayVerse!;
    }

    // Verificar si ya tenemos el versículo del día en caché
    final cachedVerse = CacheService.getTodayVerse();
    if (cachedVerse != null) {
      _todayVerse = cachedVerse;
      _lastDate = today;
      return _todayVerse!;
    }

    // NUEVA FUENTE: Versículo desde SQLite RV1909 usando referencias curadas
    try {
      final offlineVerse = await offline_daily.DailyVerseService().getDailyVerse(date: today);
      final ref = '${offlineVerse.book} ${offlineVerse.chapter}:${offlineVerse.verse}';
      final model = Verse(
        id: today.year * 10000 + today.month * 100 + today.day,
        text: offlineVerse.text,
        reference: ref,
        book: offlineVerse.book,
        chapter: offlineVerse.chapter,
        verse: offlineVerse.verse,
      );
      await CacheService.saveTodayVerse(model);
      _todayVerse = model;
      _lastDate = today;
      debugPrint('DailyVerse => $ref | ${offlineVerse.tag ?? ''} | ${offlineVerse.text}');
      return _todayVerse!;
    } catch (e) {
      debugPrint('Error offline daily verse: $e');
    }

    // Si falla, usar último versículo guardado
    final lastVerse = CacheService.getLastVerse();
    if (lastVerse != null) {
      _todayVerse = lastVerse;
      _lastDate = today;
      return _todayVerse!;
    }

    // Último recurso: fallo controlado
    throw Exception('No se pudo obtener el versículo del día');
  }

  /// Obtiene un versículo por su ID
  Future<Verse> getVerseById(int id) async {
    // Buscar en caché
    final cached = CacheService.getTodayVerse();
    if (cached != null && cached.id == id) {
      return cached;
    }
    throw Exception('Verse with id $id not found');
  }

  /// Obtiene todos los versículos disponibles (locales)
  Future<List<Verse>> getAllVerses() async {
    return await loadLocalVerses();
  }

  /// Fuerza la actualización del versículo del día
  Future<Verse> refreshTodayVerse() async {
    _todayVerse = null;
    _lastDate = null;
    return await getTodayVerse();
  }
}
