import 'package:flutter/foundation.dart';
import '../models/prayer.dart';
import 'prayer_api_service.dart';
import 'cache_service.dart';
import 'language_service.dart';
import 'translation_service.dart';
import 'daily_content_service.dart';
import 'storage_service.dart';

/// Servicio para gestionar oraciones diarias
/// Integra API externa con caché local y fallback
/// Usa el nuevo sistema basado en día del año
class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  final PrayerApiService _apiService = PrayerApiService();
  final TranslationService _translationService = TranslationService();
  final DailyContentService _dailyContent = DailyContentService();
  final StorageService _storageService = StorageService();
  DateTime? _lastDate;
  Prayer? _todayMorningPrayer;
  Prayer? _todayEveningPrayer;
  String? _lastTradition;
  String? _morningContext;
  String? _eveningContext;

  /// Obtiene la oración de la mañana del día actual
  Future<Prayer> getTodayMorningPrayer() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tradition = _currentTradition();
    final context = '${today.toIso8601String()}:$tradition';
    _prepareDailyContext(today, tradition);

    // Si ya tenemos la oración de hoy, retornarla
    if (_lastDate != null &&
        _todayMorningPrayer != null &&
        _morningContext == context &&
        _lastTradition == tradition &&
        _lastDate!.isAtSameMomentAs(today)) {
      return _todayMorningPrayer!;
    }

    // Verificar caché
    final cachedPrayer = CacheService.getTodayPrayer(type: 'morning');
    if (cachedPrayer != null &&
        _isPrayerForTradition(cachedPrayer.id, tradition, 'morning')) {
      _todayMorningPrayer = cachedPrayer;
      _morningContext = context;
      _lastDate = today;
      _lastTradition = tradition;
      return _todayMorningPrayer!;
    }

    // Intentar obtener desde contenidos locales usando día del año
    try {
      await _dailyContent.loadContent();
      final text = _dailyContent.getMorningPrayer(tradition: tradition);
      if (text.isNotEmpty) {
        final targetLanguage = LanguageService.getLanguage();
        final translatedText = await _translationService.translateText(
          text,
          targetLanguage,
        );
        final dayOfYear = _dailyContent.getDayOfYear();
        final prayer = Prayer(
          id: _buildStableId(
            type: 'morning',
            index: dayOfYear,
            tradition: tradition,
          ),
          text: translatedText,
          type: 'morning',
          title: targetLanguage == 'es'
              ? 'Oración de la Mañana'
              : await _translationService.translateText(
                  'Oración de la Mañana',
                  targetLanguage,
                ),
        );
        await CacheService.saveTodayPrayer(prayer);
        _todayMorningPrayer = prayer;
        _morningContext = context;
        _lastDate = today;
        _lastTradition = tradition;
        return prayer;
      }
    } catch (e) {
      debugPrint('Error getting morning prayer from daily content: $e');
    }

    // Intentar obtener desde API (fallback)
    try {
      final prayer = await _apiService.getDailyPrayer(type: 'morning');
      // Traducir la oración al idioma del usuario
      final targetLanguage = LanguageService.getLanguage();
      final translatedPrayer = await _translatePrayer(prayer, targetLanguage);

      await CacheService.saveTodayPrayer(translatedPrayer);
      _todayMorningPrayer = translatedPrayer;
      _morningContext = context;
      _lastDate = today;
      return translatedPrayer;
    } catch (e) {
      debugPrint('Error getting morning prayer: $e');

      // Fallback a última oración guardada
      final lastPrayer = CacheService.getLastPrayer(type: 'morning');
      if (lastPrayer != null &&
          _isPrayerForTradition(lastPrayer.id, tradition, 'morning')) {
        final targetLanguage = LanguageService.getLanguage();
        final translatedPrayer = await _translatePrayer(
          lastPrayer,
          targetLanguage,
        );
        _todayMorningPrayer = translatedPrayer;
        _morningContext = context;
        return translatedPrayer;
      }

      // Último recurso: obtener una oración local
      final prayer = await _apiService.getDailyPrayer(type: 'morning');
      final targetLanguage = LanguageService.getLanguage();
      final translatedPrayer = await _translatePrayer(prayer, targetLanguage);
      _todayMorningPrayer = translatedPrayer;
      _morningContext = context;
      return translatedPrayer;
    }
  }

  /// Obtiene la oración de la noche del día actual
  Future<Prayer> getTodayEveningPrayer() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tradition = _currentTradition();
    final context = '${today.toIso8601String()}:$tradition';
    _prepareDailyContext(today, tradition);

    // Si ya tenemos la oración de hoy, retornarla
    if (_lastDate != null &&
        _todayEveningPrayer != null &&
        _eveningContext == context &&
        _lastTradition == tradition &&
        _lastDate!.isAtSameMomentAs(today)) {
      return _todayEveningPrayer!;
    }

    // Verificar caché
    final cachedPrayer = CacheService.getTodayPrayer(type: 'evening');
    if (cachedPrayer != null &&
        _isPrayerForTradition(cachedPrayer.id, tradition, 'evening')) {
      _todayEveningPrayer = cachedPrayer;
      _eveningContext = context;
      _lastDate = today;
      _lastTradition = tradition;
      return _todayEveningPrayer!;
    }

    // Intentar obtener desde contenidos locales usando día del año
    try {
      await _dailyContent.loadContent();
      final text = _dailyContent.getNightPrayer(tradition: tradition);
      if (text.isNotEmpty) {
        final targetLanguage = LanguageService.getLanguage();
        final translatedText = await _translationService.translateText(
          text,
          targetLanguage,
        );
        final dayOfYear = _dailyContent.getDayOfYear();
        final prayer = Prayer(
          id: _buildStableId(
            type: 'evening',
            index: dayOfYear,
            tradition: tradition,
          ),
          text: translatedText,
          type: 'evening',
          title: targetLanguage == 'es'
              ? 'Oración de la Noche'
              : await _translationService.translateText(
                  'Oración de la Noche',
                  targetLanguage,
                ),
        );
        await CacheService.saveTodayPrayer(prayer);
        _todayEveningPrayer = prayer;
        _eveningContext = context;
        _lastDate = today;
        _lastTradition = tradition;
        return prayer;
      }
    } catch (e) {
      debugPrint('Error getting evening prayer from daily content: $e');
    }

    // Intentar obtener desde API (fallback)
    try {
      final prayer = await _apiService.getDailyPrayer(type: 'evening');
      // Traducir la oración al idioma del usuario
      final targetLanguage = LanguageService.getLanguage();
      final translatedPrayer = await _translatePrayer(prayer, targetLanguage);

      await CacheService.saveTodayPrayer(translatedPrayer);
      _todayEveningPrayer = translatedPrayer;
      _eveningContext = context;
      _lastDate = today;
      return translatedPrayer;
    } catch (e) {
      debugPrint('Error getting evening prayer: $e');

      // Fallback a última oración guardada
      final lastPrayer = CacheService.getLastPrayer(type: 'evening');
      if (lastPrayer != null &&
          _isPrayerForTradition(lastPrayer.id, tradition, 'evening')) {
        final targetLanguage = LanguageService.getLanguage();
        final translatedPrayer = await _translatePrayer(
          lastPrayer,
          targetLanguage,
        );
        _todayEveningPrayer = translatedPrayer;
        _eveningContext = context;
        return translatedPrayer;
      }

      // Último recurso: obtener una oración local
      final prayer = await _apiService.getDailyPrayer(type: 'evening');
      final targetLanguage = LanguageService.getLanguage();
      final translatedPrayer = await _translatePrayer(prayer, targetLanguage);
      _todayEveningPrayer = translatedPrayer;
      _eveningContext = context;
      return translatedPrayer;
    }
  }

  /// Obtiene una oración por su ID
  Future<Prayer> getPrayerById(int id) async {
    final allPrayers = _apiService.getAllLocalPrayers();
    try {
      return allPrayers.firstWhere((prayer) => prayer.id == id);
    } catch (e) {
      throw Exception('Prayer with id $id not found');
    }
  }

  /// Obtiene todas las oraciones disponibles
  Future<List<Prayer>> getAllPrayers() async {
    return _apiService.getAllLocalPrayers();
  }

  /// Traduce una oración al idioma objetivo
  Future<Prayer> _translatePrayer(Prayer prayer, String targetLanguage) async {
    try {
      // Si ya está en el idioma objetivo, retornar
      if (targetLanguage == 'es') {
        return prayer; // Las oraciones locales están en español
      }

      // Traducir el texto de la oración
      final translatedText = await _translationService.translateText(
        prayer.text,
        targetLanguage,
      );

      // Traducir el título
      final translatedTitle = await _translationService.translateText(
        prayer.title,
        targetLanguage,
      );

      return Prayer(
        id: prayer.id,
        text: translatedText,
        type: prayer.type,
        title: translatedTitle,
      );
    } catch (e) {
      debugPrint('Error translating prayer: $e');
      return prayer; // Retornar oración original si falla
    }
  }

  String _currentTradition() {
    final v = _storageService.getValidatedTraditionalPrayersReligion().trim();
    return v.isEmpty ? 'catolica' : v;
  }

  void _prepareDailyContext(DateTime today, String tradition) {
    if (_lastDate != today || _lastTradition != tradition) {
      resetInMemoryDailyPrayers();
      _lastDate = today;
      _lastTradition = tradition;
    }
  }

  /// Tras cambiar tradición en Ajustes: evita mezclar oraciones en memoria con la tradición anterior.
  void resetInMemoryDailyPrayers() {
    _lastDate = null;
    _todayMorningPrayer = null;
    _todayEveningPrayer = null;
    _lastTradition = null;
    _morningContext = null;
    _eveningContext = null;
  }

  int _buildStableId({
    required String type,
    required int index,
    required String tradition,
  }) {
    // IDs estables: 1xxxx para morning, 2xxxx para evening
    final traditionOffset = tradition == 'cristiana' || tradition == 'general'
        ? 50000
        : 0;
    final base = type == 'morning' ? 10000 : 20000;
    return traditionOffset + base + index;
  }

  bool _isPrayerForTradition(int id, String tradition, String type) {
    // Legacy timestamp IDs do not identify a tradition. Reload the bundled
    // catalog instead of accepting every large ID as evangelical content.
    final first = _buildStableId(type: type, index: 1, tradition: tradition);
    return id >= first && id <= first + 365;
  }
}
