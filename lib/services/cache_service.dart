import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/verse.dart';
import '../models/prayer.dart';

/// Servicio para gestionar caché local de versículos y oraciones
/// Asegura que los datos estén disponibles offline
class CacheService {
  static const String _verseCacheBoxName = 'verse_cache';
  static const String _prayerCacheBoxName = 'prayer_cache';
  static const String _lastVerseDateKey = 'last_verse_date';
  static const String _lastVerseIdKey = 'last_verse_id';
  static const String _todayVerseKey = 'today_verse';
  static const String _todayMorningPrayerKey = 'today_morning_prayer';
  static const String _todayEveningPrayerKey = 'today_evening_prayer';

  static Future<void> init() async {
    try {
      await Hive.openBox(_verseCacheBoxName);
      await Hive.openBox(_prayerCacheBoxName);
    } catch (e) {
      debugPrint('Error initializing cache service: $e');
    }
  }

  static Box get _verseBox => Hive.box(_verseCacheBoxName);
  static Box get _prayerBox => Hive.box(_prayerCacheBoxName);

  /// Guarda el versículo del día en caché
  static Future<void> saveTodayVerse(Verse verse) async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      await _verseBox.put(_todayVerseKey, verse.toJson());
      await _verseBox.put(_lastVerseDateKey, todayString);
      await _verseBox.put(_lastVerseIdKey, verse.id);
    } catch (e) {
      debugPrint('Error saving verse to cache: $e');
    }
  }

  /// Obtiene el versículo del día desde caché
  static Verse? getTodayVerse() {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      final lastDate = _verseBox.get(_lastVerseDateKey) as String?;
      
      // Si es el mismo día, retornar el versículo guardado
      if (lastDate == todayString) {
        final verseData = _verseBox.get(_todayVerseKey);
        if (verseData != null) {
          return Verse.fromJson(verseData as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error getting verse from cache: $e');
    }
    return null;
  }

  /// Obtiene el último versículo guardado (del día anterior si es necesario)
  static Verse? getLastVerse() {
    try {
      final verseData = _verseBox.get(_todayVerseKey);
      if (verseData != null) {
        return Verse.fromJson(verseData as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting last verse: $e');
    }
    return null;
  }

  /// Verifica si el versículo del día ya está en caché
  static bool hasTodayVerse() {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      final lastDate = _verseBox.get(_lastVerseDateKey) as String?;
      return lastDate == todayString;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el ID del último versículo mostrado
  static int? getLastVerseId() {
    try {
      return _verseBox.get(_lastVerseIdKey) as int?;
    } catch (e) {
      return null;
    }
  }

  /// Guarda la oración del día en caché
  static Future<void> saveTodayPrayer(Prayer prayer) async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      final key = prayer.type == 'morning' 
          ? _todayMorningPrayerKey 
          : _todayEveningPrayerKey;
      
      await _prayerBox.put(key, prayer.toJson());
      await _prayerBox.put('${key}_date', todayString);
    } catch (e) {
      debugPrint('Error saving prayer to cache: $e');
    }
  }

  /// Obtiene la oración del día desde caché
  static Prayer? getTodayPrayer({required String type}) {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      final key = type == 'morning' 
          ? _todayMorningPrayerKey 
          : _todayEveningPrayerKey;
      
      final lastDate = _prayerBox.get('${key}_date') as String?;
      
      // Si es el mismo día, retornar la oración guardada
      if (lastDate == todayString) {
        final prayerData = _prayerBox.get(key);
        if (prayerData != null) {
          return Prayer.fromJson(prayerData as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error getting prayer from cache: $e');
    }
    return null;
  }

  /// Obtiene la última oración guardada
  static Prayer? getLastPrayer({required String type}) {
    try {
      final key = type == 'morning' 
          ? _todayMorningPrayerKey 
          : _todayEveningPrayerKey;
      
      final prayerData = _prayerBox.get(key);
      if (prayerData != null) {
        return Prayer.fromJson(prayerData as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting last prayer: $e');
    }
    return null;
  }

  /// Limpia el caché (útil para testing o reset)
  static Future<void> clearCache() async {
    try {
      await _verseBox.clear();
      await _prayerBox.clear();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}

