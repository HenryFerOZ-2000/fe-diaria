class EmotionPassage {
  final String id;
  final String book;
  final int chapter;
  final int? verseStart;
  final int? verseEnd;
  final String label;

  const EmotionPassage({
    required this.id,
    required this.book,
    required this.chapter,
    required this.label,
    this.verseStart,
    this.verseEnd,
  });

  factory EmotionPassage.fromJson(Map<String, dynamic> json) {
    return EmotionPassage(
      id: json['id'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verseStart: json['verseStart'] as int?,
      verseEnd: json['verseEnd'] as int?,
      label: json['label'] as String,
    );
  }
}

