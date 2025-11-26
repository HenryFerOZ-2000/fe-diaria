/// Modelo para Salmos por categoría
class Psalm {
  final int id;
  final String title;
  final String text;
  final String category; // protección, agradecimiento, consuelo, etc.
  final String? reference;
  final List<String>? tags;

  Psalm({
    required this.id,
    required this.title,
    required this.text,
    required this.category,
    this.reference,
    this.tags,
  });

  factory Psalm.fromJson(Map<String, dynamic> json) {
    return Psalm(
      id: json['id'] as int,
      title: json['title'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      reference: json['reference'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'category': category,
      'reference': reference,
      'tags': tags,
    };
  }
}

