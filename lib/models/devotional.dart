/// Modelo para devocionales diarios
class Devotional {
  final int id;
  final String title;
  final String verse;
  final String verseReference;
  final String reflection;
  final DateTime? date;
  final List<String>? tags;

  Devotional({
    required this.id,
    required this.title,
    required this.verse,
    required this.verseReference,
    required this.reflection,
    this.date,
    this.tags,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'] as int,
      title: json['title'] as String,
      verse: json['verse'] as String,
      verseReference: json['verseReference'] as String,
      reflection: json['reflection'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'verse': verse,
      'verseReference': verseReference,
      'reflection': reflection,
      'date': date?.toIso8601String(),
      'tags': tags,
    };
  }
}

