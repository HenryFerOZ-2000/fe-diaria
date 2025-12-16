import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_passage.dart';
import '../repositories/emotion_passage_repository.dart';

class PassageRotationService {
  final EmotionPassageRepository _repo;
  final Random _random;

  PassageRotationService({
    EmotionPassageRepository? repository,
    Random? random,
  })  : _repo = repository ?? EmotionPassageRepository(),
        _random = random ?? Random();

  String _keyFor(String emotion) => 'seen_passages_$emotion';

  Future<EmotionPassage?> next(String emotion) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_keyFor(emotion)) ?? [];
    final passages = await _repo.getByEmotion(emotion);
    if (passages.isEmpty) return null;

    var available = passages.where((p) => !seen.contains(p.id)).toList();
    if (available.isEmpty) {
      await prefs.remove(_keyFor(emotion));
      available = passages;
      seen.clear();
    }

    final passage = available[_random.nextInt(available.length)];
    await prefs.setStringList(_keyFor(emotion), [...seen, passage.id]);
    return passage;
  }

  Future<void> resetEmotion(String emotion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(emotion));
  }
}

