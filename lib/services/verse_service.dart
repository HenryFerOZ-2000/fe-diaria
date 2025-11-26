import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/verse.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'language_service.dart';
import 'translation_service.dart';
import 'daily_content_service.dart';

/// Servicio para gestionar versículos bíblicos
/// Integra API externa con caché local y fallback
/// Usa el nuevo sistema basado en día del año
class VerseService {
  static final VerseService _instance = VerseService._internal();
  factory VerseService() => _instance;
  VerseService._internal();

  final ApiService _apiService = ApiService();
  final TranslationService _translationService = TranslationService();
  final DailyContentService _dailyContent = DailyContentService();
  DateTime? _lastDate;
  Verse? _todayVerse;

  /// Carga versículos locales desde el archivo JSON unificado
  Future<List<Verse>> loadLocalVerses() async {
    await _dailyContent.loadContent();
    final versesData = _dailyContent.getAllVersesData();
    return versesData.map((v) => Verse.fromJson(v)).toList();
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

    // PRIORIDAD: Usar versículos locales primero (traducir si es necesario)
    try {
      await _dailyContent.loadContent();
      final verseData = _dailyContent.getTodayVerseData();
      final localVerse = Verse.fromJson(verseData);
      
      // Traducir si el idioma no es español
      final targetLanguage = LanguageService.getLanguage();
      final translatedVerse = targetLanguage != 'es'
          ? await _translateLocalVerse(localVerse, targetLanguage)
          : localVerse;
      
      // Guardar en caché
      await CacheService.saveTodayVerse(translatedVerse);
      _todayVerse = translatedVerse;
      _lastDate = today;
      return _todayVerse!;
    } catch (e) {
      debugPrint('Error getting local verse: $e');
    }

    // Si no hay versículos locales, usar el último versículo guardado
    final lastVerse = CacheService.getLastVerse();
    if (lastVerse != null) {
      _todayVerse = lastVerse;
      _lastDate = today;
      return _todayVerse!;
    }

    // Último recurso: intentar desde API (puede estar en inglés)
    Verse? apiVerse;
    try {
      apiVerse = await _apiService.getDailyVerse();
      
      if (apiVerse != null) {
        // Verificar que no sea el mismo versículo de ayer
        final lastVerseId = CacheService.getLastVerseId();
        if (lastVerseId != null && apiVerse.id == lastVerseId) {
          // Si es el mismo, obtener uno diferente desde local
          apiVerse = await _getDifferentLocalVerse(lastVerseId);
        }
        
        // Guardar en caché
        await CacheService.saveTodayVerse(apiVerse!);
        _todayVerse = apiVerse;
        _lastDate = today;
        return _todayVerse!;
      }
    } catch (e) {
      debugPrint('Error getting verse from API: $e');
    }

    // Si todo falla, lanzar excepción
    throw Exception('No se pudo obtener un versículo');
  }

  /// Traduce un versículo local al idioma objetivo
  Future<Verse> _translateLocalVerse(Verse verse, String targetLanguage) async {
    try {
      final translatedText = await _translationService.translateText(
        verse.text,
        targetLanguage,
      );
      return Verse(
        id: verse.id,
        text: translatedText,
        reference: verse.reference,
        book: verse.book,
        chapter: verse.chapter,
        verse: verse.verse,
      );
    } catch (_) {
      return verse;
    }
  }


  Future<Verse?> _getDifferentLocalVerse(int lastId) async {
    final verses = await loadLocalVerses();
    if (verses.isEmpty) return null;

    final different = verses.where((v) => v.id != lastId).toList();
    if (different.isEmpty) return verses.first;

    final random = Random();
    return different[random.nextInt(different.length)];
  }

  /// Obtiene un versículo por su ID
  Future<Verse> getVerseById(int id) async {
    // Primero buscar en caché
    final cached = CacheService.getTodayVerse();
    if (cached != null && cached.id == id) {
      return cached;
    }

    // Buscar en versículos locales
    final verses = await loadLocalVerses();
    try {
      return verses.firstWhere((verse) => verse.id == id);
    } catch (e) {
      throw Exception('Verse with id $id not found');
    }
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
