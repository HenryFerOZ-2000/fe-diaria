class HelloAoTranslation {
  final String id;
  final String name;
  final String? englishName;
  final String? language;
  final String? languageName;
  final String? languageEnglishName;

  HelloAoTranslation({
    required this.id,
    required this.name,
    this.englishName,
    this.language,
    this.languageName,
    this.languageEnglishName,
  });

  factory HelloAoTranslation.fromJson(Map<String, dynamic> json) {
    return HelloAoTranslation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString(),
      language: json['language']?.toString(),
      languageName: json['languageName']?.toString(),
      languageEnglishName: json['languageEnglishName']?.toString(),
    );
  }
}

class HelloAoVerse {
  final int number;
  final List<dynamic> content;

  HelloAoVerse({required this.number, required this.content});
}

class HelloAoChapter {
  final String bookId;
  final int chapterNumber;
  final List<HelloAoVerse> verses;

  HelloAoChapter({
    required this.bookId,
    required this.chapterNumber,
    required this.verses,
  });

  factory HelloAoChapter.fromJson(Map<String, dynamic> json) {
    final bookId = json['bookId']?.toString() ?? '';
    final chapterNumber = (json['chapter'] as num?)?.toInt() ?? 0;
    final rawContent = json['content'];
    List<dynamic> contentList;
    if (rawContent is List) {
      contentList = rawContent;
    } else if (rawContent is Map && rawContent['content'] is List) {
      contentList = rawContent['content'] as List<dynamic>;
    } else if (rawContent is Map) {
      // Algunos endpoints pueden devolver un mapa de versos: { "1": {...}, "2": {...} }
      // Intentamos convertir sus values a lista preservando el orden por clave numérica si aplica.
      final entries = rawContent.entries.toList();
      entries.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      contentList = entries.map((e) => e.value).toList();
    } else {
      throw Exception(
          'Formato inesperado de capítulo: se esperaba lista en content');
    }
    final content = contentList.whereType<Map<String, dynamic>>();

    final verses = content
        .where((item) => item['type'] == 'verse')
        .map((item) {
          final number = (item['number'] as num?)?.toInt() ?? 0;
          final rawContent = item['content'] as List<dynamic>? ?? const [];
          return HelloAoVerse(number: number, content: rawContent);
        })
        .toList();

    return HelloAoChapter(
      bookId: bookId,
      chapterNumber: chapterNumber,
      verses: verses,
    );
  }
}

