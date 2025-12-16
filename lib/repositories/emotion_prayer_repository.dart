import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/emotion_prayer.dart';

class EmotionPrayerRepository {
  static final EmotionPrayerRepository _instance =
      EmotionPrayerRepository._internal();
  factory EmotionPrayerRepository() => _instance;
  EmotionPrayerRepository._internal();

  Map<String, List<EmotionPrayer>>? _cache;

  Future<void> _load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/emotion_prayers.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _cache = data.map((category, list) {
      final prayers = (list as List<dynamic>)
          .map((e) => EmotionPrayer.fromJson(category, e as Map<String, dynamic>))
          .toList();
      return MapEntry(category, prayers);
    });
  }

  Future<List<EmotionPrayer>> getByCategory(String category) async {
    await _load();
    return _cache?[category] ?? <EmotionPrayer>[];
  }
}

