import 'package:flutter/services.dart' show rootBundle;
import '../models/prayer_model.dart';

class PrayerRepository {
  static final PrayerRepository _instance = PrayerRepository._internal();
  factory PrayerRepository() => _instance;
  PrayerRepository._internal();

  List<PrayerModel>? _cache;

  Future<List<PrayerModel>> _loadAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/prayers.json');
    _cache = PrayerModel.listFromJson(jsonStr);
    return _cache!;
  }

  Future<List<PrayerModel>> getByCategory(String category) async {
    final all = await _loadAll();
    return all.where((p) => p.category == category).toList();
  }
}

