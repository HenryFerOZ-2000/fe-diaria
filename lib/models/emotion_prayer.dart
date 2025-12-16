class EmotionPrayer {
  final String id;
  final String category;
  final String title;
  final String text;
  final List<String> tags;
  final String? verseRef;

  const EmotionPrayer({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
    required this.tags,
    this.verseRef,
  });

  factory EmotionPrayer.fromJson(String category, Map<String, dynamic> json) {
    return EmotionPrayer(
      id: json['id'] as String,
      category: category,
      title: json['title'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      verseRef: json['verseRef'] as String?,
    );
  }
}

