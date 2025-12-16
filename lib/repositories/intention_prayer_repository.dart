import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/intention_prayer.dart';

class IntentionPrayerRepository {
  static final IntentionPrayerRepository _instance =
      IntentionPrayerRepository._internal();
  factory IntentionPrayerRepository() => _instance;
  IntentionPrayerRepository._internal();

  Map<String, List<IntentionPrayer>>? _cache;

  Future<void> _load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/intention_prayers.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _cache = data.map((category, list) {
      final prayers = (list as List<dynamic>)
          .map((e) =>
              IntentionPrayer.fromJson(category, e as Map<String, dynamic>))
          .toList();
      return MapEntry(category, prayers);
    });
  }

  Future<List<IntentionPrayer>> getByCategory(String category) async {
    await _load();
    return _cache?[category] ?? <IntentionPrayer>[];
  }
}

