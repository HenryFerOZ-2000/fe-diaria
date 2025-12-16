class TraditionalPrayer {
  final String id;
  final String title;
  final String type; // fixed_text | bible_passage
  final String? text;
  final String? book;
  final int? chapter;
  final int? verseStart;
  final int? verseEnd;
  final String? label;

  const TraditionalPrayer({
    required this.id,
    required this.title,
    required this.type,
    this.text,
    this.book,
    this.chapter,
    this.verseStart,
    this.verseEnd,
    this.label,
  });

  factory TraditionalPrayer.fromJson(Map<String, dynamic> json) {
    return TraditionalPrayer(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      text: json['text'] as String?,
      book: json['book'] as String?,
      chapter: json['chapter'] as int?,
      verseStart: json['verseStart'] as int?,
      verseEnd: json['verseEnd'] as int?,
      label: json['label'] as String?,
    );
  }
}

