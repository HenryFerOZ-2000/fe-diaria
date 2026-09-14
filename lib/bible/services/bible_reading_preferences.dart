import 'package:shared_preferences/shared_preferences.dart';

class BibleReadingPosition {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;

  const BibleReadingPosition({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
  });
}

class BibleReadingPreferences {
  static const _bookIdKey = 'bible_last_book_id';
  static const _bookNameKey = 'bible_last_book_name';
  static const _chapterKey = 'bible_last_chapter';
  static const _verseKey = 'bible_last_verse';
  static const _recentBooksKey = 'bible_recent_books';
  static const _fontSizeKey = 'bible_reader_font_size';
  static const _lineHeightKey = 'bible_reader_line_height';
  static const _toneKey = 'bible_reader_tone';
  static const _highlightsKey = 'bible_highlights';

  Future<BibleReadingPosition?> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final bookId = prefs.getString(_bookIdKey);
    final bookName = prefs.getString(_bookNameKey);
    final chapter = prefs.getInt(_chapterKey);
    if (bookId == null || bookName == null || chapter == null) return null;
    return BibleReadingPosition(
      bookId: bookId,
      bookName: bookName,
      chapter: chapter,
      verse: prefs.getInt(_verseKey) ?? 1,
    );
  }

  Future<void> savePosition(BibleReadingPosition position) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_bookIdKey, position.bookId),
      prefs.setString(_bookNameKey, position.bookName),
      prefs.setInt(_chapterKey, position.chapter),
      prefs.setInt(_verseKey, position.verse),
    ]);
    final recent = prefs.getStringList(_recentBooksKey) ?? <String>[];
    await prefs.setStringList(
      _recentBooksKey,
      [
        position.bookId,
        ...recent.where((id) => id != position.bookId),
      ].take(5).toList(),
    );
  }

  Future<List<String>> getRecentBookIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentBooksKey) ?? <String>[];
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 18;
  }

  Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  Future<double> getLineHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lineHeightKey) ?? 1.65;
  }

  Future<void> setLineHeight(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineHeightKey, value);
  }

  Future<String> getTone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_toneKey) ?? 'system';
  }

  Future<void> setTone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_toneKey, value);
  }

  String highlightKey(String bookId, int chapter, int verse) =>
      '$bookId:$chapter:$verse';

  Future<Set<String>> getHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_highlightsKey) ?? <String>[]).toSet();
  }

  Future<void> toggleHighlights(Iterable<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getStringList(_highlightsKey) ?? <String>[]).toSet();
    final allSelected = keys.every(saved.contains);
    if (allSelected) {
      saved.removeAll(keys);
    } else {
      saved.addAll(keys);
    }
    await prefs.setStringList(_highlightsKey, saved.toList());
  }
}
