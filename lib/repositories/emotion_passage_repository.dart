import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/emotion_passage.dart';

class EmotionPassageRepository {
  static final EmotionPassageRepository _instance =
      EmotionPassageRepository._internal();
  factory EmotionPassageRepository() => _instance;
  EmotionPassageRepository._internal();

  Map<String, List<EmotionPassage>>? _cache;

  Future<void> _load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/emotion_passages.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _cache = data.map((key, value) {
      final list = (value as List<dynamic>)
          .map((e) => EmotionPassage.fromJson(e as Map<String, dynamic>))
          .toList();
      return MapEntry(key, list);
    });
  }

  Future<List<EmotionPassage>> getByEmotion(String emotionKey) async {
    await _load();
    return _cache?[emotionKey] ?? <EmotionPassage>[];
  }
}

