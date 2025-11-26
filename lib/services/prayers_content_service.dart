import 'dart:convert';
import 'package:flutter/services.dart';

class PrayersContentService {
  static final PrayersContentService _instance = PrayersContentService._internal();
  factory PrayersContentService() => _instance;
  PrayersContentService._internal();

  List<String>? _morning365; // index day-1
  List<String>? _night365; // index day-1

  Future<List<String>> loadMorning365() async {
    if (_morning365 != null) return _morning365!;
    final list = await _loadJsonList('assets/prayers/morning_365.json');
    _morning365 = list.map<String>((e) => (e['text'] as String)).toList();
    return _morning365!;
  }

  Future<List<String>> loadNight365() async {
    if (_night365 != null) return _night365!;
    final list = await _loadJsonList('assets/prayers/night_365.json');
    _night365 = list.map<String>((e) => (e['text'] as String)).toList();
    return _night365!;
  }

  Future<List<dynamic>> _loadJsonList(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as List<dynamic>;
  }
}
