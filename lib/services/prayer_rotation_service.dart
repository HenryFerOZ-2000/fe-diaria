import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';
import '../repositories/prayer_repository.dart';

class PrayerRotationService {
  final PrayerRepository _repository;
  final Random _random;

  PrayerRotationService({
    PrayerRepository? repository,
    Random? random,
  })  : _repository = repository ?? PrayerRepository(),
        _random = random ?? Random();

  String _keyFor(String category) => 'seen_prayers_$category';

  Future<PrayerModel> nextPrayer(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_keyFor(category)) ?? [];
    final prayers = await _repository.getByCategory(category);

    var available = prayers.where((p) => !seen.contains(p.id)).toList();
    if (available.isEmpty) {
      await prefs.remove(_keyFor(category));
      available = prayers;
      seen.clear();
    }

    final prayer = available[_random.nextInt(available.length)];
    await prefs.setStringList(_keyFor(category), [...seen, prayer.id]);
    return prayer;
  }

  Future<void> resetCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(category));
  }
}

