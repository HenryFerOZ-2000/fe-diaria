import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/verse.dart';
import '../models/prayer.dart';

/// Servicio de almacenamiento local usando Hive
/// Gestiona favoritos y configuraciones de la aplicación
class StorageService {
  static const String _favoritesBoxName = 'favorites';
  static const String _settingsBoxName = 'settings';
  
  // Claves de configuración
  static const String _darkModeKey = 'darkMode';
  static const String _notificationEnabledKey = 'notificationEnabled';
  static const String _morningVerseNotificationTimeKey = 'morningVerseNotificationTime'; // AM - Versículo
  static const String _eveningPrayerNotificationTimeKey = 'eveningPrayerNotificationTime'; // PM - Oración
  static const String _morningNotificationEnabledKey = 'morningNotificationEnabled';
  static const String _eveningNotificationEnabledKey = 'eveningNotificationEnabled';
  static const String _hourlyRemindersEnabledKey = 'hourlyRemindersEnabled';
  static const String _fontSizeKey = 'fontSize';
  static const String _readingModeKey = 'readingMode';
  static const String _soundEnabledKey = 'soundEnabled';
  static const String _userNameKey = 'userName';
  static const String _userEmotionKey = 'userEmotion';
  static const String _onboardingCompletedKey = 'onboardingCompleted';
  static const String _traditionalPrayersReligionKey = 'traditionalPrayersReligion'; // 'catolica' o 'cristiana'
  static const String _streakCountKey = 'streakCount';
  static const String _lastStreakDateKey = 'lastStreakDate';
  static const String _savedPrayersKey = 'savedPrayers';

  // Monetización
  static const String _adsRemovedKey = 'adsRemoved'; // Pago único realizado
  static const String _dailyInterstitialDateKey = 'dailyInterstitialDate'; // yyyy-MM-dd
  static const String _dailyInterstitialCountKey = 'dailyInterstitialCount'; // 0..2
  static const String _morningInterstitialShownDateKey = 'morningInterstitialShownDate'; // yyyy-MM-dd
  static const String _nightInterstitialShownDateKey = 'nightInterstitialShownDate'; // yyyy-MM-dd

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_favoritesBoxName);
      await Hive.openBox(_settingsBoxName);
    } catch (e) {
      // Si Hive ya está inicializado, continuar
      debugPrint('Hive initialization note: $e');
      try {
        await Hive.openBox(_favoritesBoxName);
        await Hive.openBox(_settingsBoxName);
      } catch (e2) {
        debugPrint('Error opening Hive boxes: $e2');
        rethrow;
      }
    }
  }

  // Favoritos
  static Box get _favoritesBox => Hive.box(_favoritesBoxName);
  static Box get _settingsBox => Hive.box(_settingsBoxName);

  Future<void> addFavorite(Verse verse) async {
    await _favoritesBox.put(verse.id.toString(), verse.toJson());
  }

  Future<void> removeFavorite(int verseId) async {
    await _favoritesBox.delete(verseId.toString());
  }

  bool isFavorite(int verseId) {
    return _favoritesBox.containsKey(verseId.toString());
  }

  List<Verse> getFavorites() {
    final keys = _favoritesBox.keys;
    return keys
        .map((key) => Verse.fromJson(_favoritesBox.get(key) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // Más recientes primero
  }

  // Configuración
  bool getDarkMode() {
    return _settingsBox.get(_darkModeKey, defaultValue: false) as bool;
  }

  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put(_darkModeKey, value);
  }

  bool getNotificationEnabled() {
    return _settingsBox.get(_notificationEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setNotificationEnabled(bool value) async {
    await _settingsBox.put(_notificationEnabledKey, value);
  }

  // Notificación de la mañana (versículo) - AM
  String getMorningVerseNotificationTime() {
    return _settingsBox.get(_morningVerseNotificationTimeKey, defaultValue: '09:00') as String;
  }

  Future<void> setMorningVerseNotificationTime(String time) async {
    await _settingsBox.put(_morningVerseNotificationTimeKey, time);
  }

  // Notificación de la noche (oración) - PM
  String getEveningPrayerNotificationTime() {
    return _settingsBox.get(_eveningPrayerNotificationTimeKey, defaultValue: '21:00') as String;
  }

  Future<void> setEveningPrayerNotificationTime(String time) async {
    await _settingsBox.put(_eveningPrayerNotificationTimeKey, time);
  }

  // Notificación de la mañana habilitada
  bool getMorningNotificationEnabled() {
    return _settingsBox.get(_morningNotificationEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setMorningNotificationEnabled(bool value) async {
    await _settingsBox.put(_morningNotificationEnabledKey, value);
  }

  // Notificación de la noche habilitada
  bool getEveningNotificationEnabled() {
    return _settingsBox.get(_eveningNotificationEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setEveningNotificationEnabled(bool value) async {
    await _settingsBox.put(_eveningNotificationEnabledKey, value);
  }

  // Recordatorios cada 3 horas habilitados
  bool getHourlyRemindersEnabled() {
    return _settingsBox.get(_hourlyRemindersEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setHourlyRemindersEnabled(bool value) async {
    await _settingsBox.put(_hourlyRemindersEnabledKey, value);
  }

  // Tamaño de fuente (1.0 = normal, 0.8 = pequeño, 1.2 = grande, 1.4 = muy grande)
  double getFontSize() {
    return _settingsBox.get(_fontSizeKey, defaultValue: 1.0) as double;
  }

  Future<void> setFontSize(double size) async {
    // Limitar el tamaño entre 0.8 y 1.4
    final clampedSize = size.clamp(0.8, 1.4);
    await _settingsBox.put(_fontSizeKey, clampedSize);
  }

  // Modo lectura (pantalla completa sin distracciones)
  bool getReadingMode() {
    return _settingsBox.get(_readingModeKey, defaultValue: false) as bool;
  }

  Future<void> setReadingMode(bool value) async {
    await _settingsBox.put(_readingModeKey, value);
  }

  // Sonido al mostrar versículo
  bool getSoundEnabled() {
    return _settingsBox.get(_soundEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setSoundEnabled(bool value) async {
    await _settingsBox.put(_soundEnabledKey, value);
  }

  // Personalización del usuario
  String getUserName() {
    return _settingsBox.get(_userNameKey, defaultValue: '') as String;
  }

  Future<void> setUserName(String name) async {
    await _settingsBox.put(_userNameKey, name);
  }

  String getUserEmotion() {
    return _settingsBox.get(_userEmotionKey, defaultValue: '') as String;
  }

  Future<void> setUserEmotion(String emotion) async {
    await _settingsBox.put(_userEmotionKey, emotion);
  }

  // Onboarding
  bool getOnboardingCompleted() {
    return _settingsBox.get(_onboardingCompletedKey, defaultValue: false) as bool;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _settingsBox.put(_onboardingCompletedKey, value);
  }

  // Monetización: Remover anuncios
  bool getAdsRemoved() {
    return _settingsBox.get(_adsRemovedKey, defaultValue: false) as bool;
  }

  Future<void> setAdsRemoved(bool value) async {
    await _settingsBox.put(_adsRemovedKey, value);
  }

  // Monetización: Control diario de interstitials (máx 2 por día)
  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int getDailyInterstitialCount() {
    final today = _todayString();
    final savedDate = _settingsBox.get(_dailyInterstitialDateKey, defaultValue: '') as String;
    if (savedDate != today) return 0;
    return _settingsBox.get(_dailyInterstitialCountKey, defaultValue: 0) as int;
  }

  Future<void> incrementDailyInterstitialCount() async {
    final today = _todayString();
    final savedDate = _settingsBox.get(_dailyInterstitialDateKey, defaultValue: '') as String;
    if (savedDate != today) {
      await _settingsBox.put(_dailyInterstitialDateKey, today);
      await _settingsBox.put(_dailyInterstitialCountKey, 1);
    } else {
      final current = _settingsBox.get(_dailyInterstitialCountKey, defaultValue: 0) as int;
      await _settingsBox.put(_dailyInterstitialCountKey, (current + 1).clamp(0, 2));
    }
  }

  bool getMorningInterstitialShownToday() {
    final today = _todayString();
    final savedDate = _settingsBox.get(_morningInterstitialShownDateKey, defaultValue: '') as String;
    return savedDate == today;
  }

  Future<void> markMorningInterstitialShown() async {
    await _settingsBox.put(_morningInterstitialShownDateKey, _todayString());
  }

  bool getNightInterstitialShownToday() {
    final today = _todayString();
    final savedDate = _settingsBox.get(_nightInterstitialShownDateKey, defaultValue: '') as String;
    return savedDate == today;
  }

  Future<void> markNightInterstitialShown() async {
    await _settingsBox.put(_nightInterstitialShownDateKey, _todayString());
  }

  // Oraciones tradicionales - Preferencia de religión
  String getTraditionalPrayersReligion() {
    return _settingsBox.get(_traditionalPrayersReligionKey, defaultValue: '') as String;
  }

  Future<void> setTraditionalPrayersReligion(String religion) async {
    await _settingsBox.put(_traditionalPrayersReligionKey, religion);
  }

  // Intenciones del día
  static const String _dailyIntentionsKey = 'dailyIntentions';

  List<String> getDailyIntentions() {
    final saved = _settingsBox.get(_dailyIntentionsKey, defaultValue: <String>[]) as List<dynamic>?;
    return saved?.cast<String>() ?? [];
  }

  Future<void> saveDailyIntentions(List<String> intentions) async {
    await _settingsBox.put(_dailyIntentionsKey, intentions);
  }

  // Progreso de la Novena
  static const String _novenaLastDayKey = 'novenaLastDay';
  static const String _novenaLastStepKey = 'novenaLastStep';

  int? getNovenaLastDay() {
    return _settingsBox.get(_novenaLastDayKey) as int?;
  }

  int? getNovenaLastStep() {
    return _settingsBox.get(_novenaLastStepKey) as int?;
  }

  Future<void> saveNovenaProgress(int day, int step) async {
    await _settingsBox.put(_novenaLastDayKey, day);
    await _settingsBox.put(_novenaLastStepKey, step);
  }

  // Utilidades genéricas para almacenaje simple (ej. resaltados)
  Future<void> setCustomString(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  String? getCustomString(String key) {
    return _settingsBox.get(key) as String?;
  }

  Future<void> removeCustom(String key) async {
    await _settingsBox.delete(key);
  }

  List<String> getKeysWithPrefix(String prefix) {
    return _settingsBox.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => k.toString())
        .toList();
  }

  // Racha diaria
  int getStreakCount() {
    return _settingsBox.get(_streakCountKey, defaultValue: 0) as int;
  }

  DateTime? getLastStreakDate() {
    final raw = _settingsBox.get(_lastStreakDateKey, defaultValue: '') as String;
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveStreakData({
    required int streakCount,
    required DateTime lastDate,
  }) async {
    await _settingsBox.put(_streakCountKey, streakCount);
    await _settingsBox.put(_lastStreakDateKey, lastDate.toIso8601String());
  }

  // Oraciones guardadas
  List<Prayer> getSavedPrayers() {
    final raw = _settingsBox.get(_savedPrayersKey, defaultValue: <dynamic>[]) as List<dynamic>;
    return raw
        .map((item) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            return Prayer.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<Prayer>()
        .toList();
  }

  Future<void> saveSavedPrayers(List<Prayer> prayers) async {
    final payload = prayers.map((p) => p.toJson()).toList();
    await _settingsBox.put(_savedPrayersKey, payload);
  }

  Future<void> addSavedPrayer(Prayer prayer) async {
    final current = getSavedPrayers();
    current.removeWhere((p) => p.id == prayer.id);
    current.add(prayer);
    await saveSavedPrayers(current);
  }

  Future<void> removeSavedPrayer(int id) async {
    final current = getSavedPrayers();
    current.removeWhere((p) => p.id == id);
    await saveSavedPrayers(current);
  }
}

