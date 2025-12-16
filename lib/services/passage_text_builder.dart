import '../models/helloao_models.dart';
import '../models/emotion_passage.dart';

class PassageTextBuilder {
  String buildPassageText(HelloAoChapter chapter, EmotionPassage passage) {
    final start = passage.verseStart ?? 1;
    final end = passage.verseEnd ?? 999;

    final selected = chapter.verses
        .where((v) => v.number >= start && v.number <= end)
        .toList();

    final buffer = StringBuffer();
    for (final verse in selected) {
      final content = verse.content.map(_stringify).join();
      final line = '${verse.number} ${content.trim()}';
      buffer.writeln(line.trim());
    }
    return buffer.toString().trim();
  }

  String _stringify(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      if (item['lineBreak'] == true) return '\n';
      if (item['text'] != null) return item['text'].toString();
    }
    return '';
  }
}

