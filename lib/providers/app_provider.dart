import 'package:flutter/material.dart';
import '../models/verse.dart';
import '../models/prayer.dart';
import '../services/verse_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/personalization_service.dart';

class AppProvider extends ChangeNotifier {
  final VerseService _verseService = VerseService();
  final PrayerService _prayerService = PrayerService();
  final StorageService _storageService = StorageService();
  late final StreakService _streakService = StreakService(_storageService);
  final NotificationService _notificationService = NotificationService();
  final PersonalizationService _personalizationService = PersonalizationService();

  Verse? _todayVerse;
  Prayer? _todayMorningPrayer;
  Prayer? _todayEveningPrayer;
  bool _isLoading = true;
  List<Verse> _favorites = [];
  List<Prayer> _savedPrayers = [];
  bool _darkMode = false;
  bool _notificationEnabled = false;
  String _morningVerseNotificationTime = '09:00'; // AM - Versículo (9:00 AM por defecto)
  String _eveningPrayerNotificationTime = '21:00'; // PM - Oración (9:00 PM por defecto)
  bool _morningNotificationEnabled = true;
  bool _eveningNotificationEnabled = true;
  bool _hourlyRemindersEnabled = true;
  double _fontSize = 1.0;
  bool _readingMode = false;
  bool _soundEnabled = false;
  int _streakCount = 0;
  final int _streakGoal = 7;

  Verse? get todayVerse => _todayVerse;
  Prayer? get todayMorningPrayer => _todayMorningPrayer;
  Prayer? get todayEveningPrayer => _todayEveningPrayer;
  
  /// Obtiene la oración del día según la hora actual
  /// Mañana: 5:00 AM - 5:59 PM
  /// Noche: 6:00 PM - 4:59 AM
  Prayer? get currentPrayer {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Oración de la mañana: 5:00 AM (5) a 5:59 PM (17)
    // Oración de la noche: 6:00 PM (18) a 4:59 AM (4)
    if (hour >= 5 && hour < 18) {
      return _todayMorningPrayer;
    } else {
      return _todayEveningPrayer;
    }
  }
  
  /// Verifica si es hora de oración de la mañana
  bool get isMorningPrayerTime {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 5 && hour < 18;
  }
  
  bool get isLoading => _isLoading;
  List<Verse> get favorites => _favorites;
  bool get darkMode => _darkMode;
  bool get notificationEnabled => _notificationEnabled;
  String get morningVerseNotificationTime => _morningVerseNotificationTime;
  String get eveningPrayerNotificationTime => _eveningPrayerNotificationTime;
  bool get morningNotificationEnabled => _morningNotificationEnabled;
  bool get eveningNotificationEnabled => _eveningNotificationEnabled;
  bool get hourlyRemindersEnabled => _hourlyRemindersEnabled;
  double get fontSize => _fontSize;
  bool get readingMode => _readingMode;
  bool get soundEnabled => _soundEnabled;
  List<Prayer> get savedPrayers => _savedPrayers;
  int get streakCount => _streakCount;
  int get streakGoal => _streakGoal;
  
  // Personalización
  String get userName => _storageService.getUserName();
  String get userEmotion => _storageService.getUserEmotion();

  AppProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _darkMode = _storageService.getDarkMode();
      _notificationEnabled = _storageService.getNotificationEnabled();
      _morningVerseNotificationTime = _storageService.getMorningVerseNotificationTime();
      _eveningPrayerNotificationTime = _storageService.getEveningPrayerNotificationTime();
      _morningNotificationEnabled = _storageService.getMorningNotificationEnabled();
      _eveningNotificationEnabled = _storageService.getEveningNotificationEnabled();
      _hourlyRemindersEnabled = _storageService.getHourlyRemindersEnabled();
      _fontSize = _storageService.getFontSize();
      _readingMode = _storageService.getReadingMode();
      _soundEnabled = _storageService.getSoundEnabled();
      
      // Si las notificaciones están habilitadas, verificar permisos y programar
      if (_notificationEnabled) {
        final permissionsGranted = await _notificationService.arePermissionsGranted();
        if (permissionsGranted) {
          // Si los permisos están concedidos, programar notificaciones
          await _notificationService.scheduleDailyNotifications();
        } else {
          // Si no están concedidos, desactivar notificaciones
          _notificationEnabled = false;
          await _storageService.setNotificationEnabled(false);
        }
      }
      
      await loadTodayVerse();
      await loadTodayPrayers();
      await loadFavorites();
      await loadSavedPrayers();
      await _updateDailyStreak();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayVerse() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Si hay una emoción seleccionada, usar versículo personalizado
      final emotion = _storageService.getUserEmotion();
      if (emotion.isNotEmpty) {
        _todayVerse = await _personalizationService.getPersonalizedVerse(emotion);
      } else {
        _todayVerse = await _verseService.getTodayVerse();
      }
      
      await _updateDailyStreak();
      
      // Actualizar widgets
      await WidgetService.updateWidget(
        verse: _todayVerse,
        morningPrayer: _todayMorningPrayer,
        eveningPrayer: _todayEveningPrayer,
      );
    } catch (e) {
      debugPrint('Error loading today verse: $e');
      // Si falla, intentar obtener el último versículo guardado desde caché
      try {
        final lastVerse = await _verseService.getTodayVerse();
        _todayVerse = lastVerse;
      } catch (e2) {
        debugPrint('Error loading fallback verse: $e2');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca el versículo del día (útil para pull-to-refresh)
  Future<void> refreshTodayVerse() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Si hay una emoción seleccionada, usar versículo personalizado
      final emotion = _storageService.getUserEmotion();
      if (emotion.isNotEmpty) {
        _todayVerse = await _personalizationService.getPersonalizedVerse(emotion);
      } else {
        _todayVerse = await _verseService.refreshTodayVerse();
      }
      
      await _updateDailyStreak();
      
      // Actualizar widgets
      await WidgetService.updateWidget(
        verse: _todayVerse,
        morningPrayer: _todayMorningPrayer,
        eveningPrayer: _todayEveningPrayer,
      );
    } catch (e) {
      debugPrint('Error refreshing verse: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayPrayers() async {
    try {
      // Siempre usar oraciones generales para mañana y noche
      // (Sin personalización ni {nombre}; sin pertenencia)
      _todayMorningPrayer = await _prayerService.getTodayMorningPrayer();
      _todayEveningPrayer = await _prayerService.getTodayEveningPrayer();
      
      // Actualizar widgets
      await WidgetService.updateWidget(
        verse: _todayVerse,
        morningPrayer: _todayMorningPrayer,
        eveningPrayer: _todayEveningPrayer,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading today prayers: $e');
    }
  }

  Future<void> loadFavorites() async {
    _favorites = _storageService.getFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(Verse verse) async {
    if (_storageService.isFavorite(verse.id)) {
      await _storageService.removeFavorite(verse.id);
    } else {
      await _storageService.addFavorite(verse);
    }
    await loadFavorites();
  }

  bool isFavorite(Verse verse) {
    return _storageService.isFavorite(verse.id);
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _storageService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
    await _storageService.setNotificationEnabled(value);
    if (value) {
      await _notificationService.scheduleDailyNotifications();
    } else {
      await _notificationService.cancelAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setMorningNotificationEnabled(bool value) async {
    _morningNotificationEnabled = value;
    await _storageService.setMorningNotificationEnabled(value);
    if (_notificationEnabled) {
      await _notificationService.refreshAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setEveningNotificationEnabled(bool value) async {
    _eveningNotificationEnabled = value;
    await _storageService.setEveningNotificationEnabled(value);
    if (_notificationEnabled) {
      await _notificationService.refreshAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setHourlyRemindersEnabled(bool value) async {
    _hourlyRemindersEnabled = value;
    await _storageService.setHourlyRemindersEnabled(value);
    if (_notificationEnabled) {
      await _notificationService.refreshAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setMorningVerseNotificationTime(String time) async {
    _morningVerseNotificationTime = time;
    await _storageService.setMorningVerseNotificationTime(time);
    if (_notificationEnabled) {
      await _notificationService.refreshAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setEveningPrayerNotificationTime(String time) async {
    _eveningPrayerNotificationTime = time;
    await _storageService.setEveningPrayerNotificationTime(time);
    if (_notificationEnabled) {
      await _notificationService.refreshAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _storageService.setFontSize(size);
    notifyListeners();
  }

  Future<void> setReadingMode(bool value) async {
    _readingMode = value;
    await _storageService.setReadingMode(value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _storageService.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> loadSavedPrayers() async {
    _savedPrayers = _storageService.getSavedPrayers();
  }

  Future<void> addSavedPrayer(Prayer prayer) async {
    await _storageService.addSavedPrayer(prayer);
    await loadSavedPrayers();
    notifyListeners();
  }

  Future<void> removeSavedPrayer(int id) async {
    await _storageService.removeSavedPrayer(id);
    await loadSavedPrayers();
    notifyListeners();
  }

  Future<void> _updateDailyStreak() async {
    try {
      final state = await _streakService.resetIfNeeded();
      _streakCount = state.count;
      debugPrint('Streak update: count=${state.count}, last=${state.lastDateYmd}');
      notifyListeners();
    } catch (e) {
      debugPrint('Streak update error: $e');
    }
  }

  Future<void> completeDailyStreak() async {
    try {
      final state = await _streakService.recordToday();
      _streakCount = state.count;
      debugPrint('Streak recorded: count=${state.count}, last=${state.lastDateYmd}');
      notifyListeners();
    } catch (e) {
      debugPrint('Streak record error: $e');
    }
  }

  // Personalización
  Future<void> setUserName(String name) async {
    await _storageService.setUserName(name);
    // Recargar oraciones si hay personalización
    final emotion = _storageService.getUserEmotion();
    if (emotion.isNotEmpty) {
      await loadTodayPrayers();
    }
    notifyListeners();
  }

  Future<void> setUserEmotion(String emotion) async {
    await _storageService.setUserEmotion(emotion);
    // Recargar versículos y oraciones personalizados
    await loadTodayVerse();
    await loadTodayPrayers();
    notifyListeners();
  }
}

