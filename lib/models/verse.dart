class Verse {
  final int id;
  final String text;
  final String reference;
  final String book;
  final int chapter;
  final int verse;

  Verse({
    required this.id,
    required this.text,
    required this.reference,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as int,
      text: json['text'] as String,
      reference: json['reference'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'reference': reference,
      'book': book,
      'chapter': chapter,
      'verse': verse,
    };
  }

  Verse copyWith({
    int? id,
    String? text,
    String? reference,
    String? book,
    int? chapter,
    int? verse,
  }) {
    return Verse(
      id: id ?? this.id,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
    );
  }
}

