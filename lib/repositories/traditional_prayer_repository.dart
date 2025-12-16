import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/traditional_prayer.dart';

class TraditionalPrayerRepository {
  static final TraditionalPrayerRepository _instance =
      TraditionalPrayerRepository._internal();
  factory TraditionalPrayerRepository() => _instance;
  TraditionalPrayerRepository._internal();

  List<TraditionalPrayer>? _cache;

  Future<List<TraditionalPrayer>> _load() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/traditional_prayers.json');
    final data = json.decode(jsonStr) as List<dynamic>;
    _cache = data
        .map((e) => TraditionalPrayer.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<TraditionalPrayer>> getAll() => _load();

  Future<TraditionalPrayer?> findById(String id) async {
    final list = await _load();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

