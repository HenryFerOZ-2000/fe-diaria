import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/verse.dart';

class BibleDb {
  BibleDb._();
  static final BibleDb instance = BibleDb._();

  static const String _assetPath = 'assets/db/rv1909.sqlite';
  // Content revision only: bookmarks remain keyed by stable book/chapter/verse.
  // Keep the earlier file intact; it contains no user reading preferences.
  static const String _dbName = 'rv1909_20260920.sqlite';

  Database? _db;
  Future<void>? _initializing;

  Future<void> verifyAndInit() async {
    await init();
  }

  Future<void> init() async {
    if (_db != null) return;
    if (_initializing != null) return _initializing!;
    final initialization = _openDatabase();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _openDatabase() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbName);

    final file = File(dbPath);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final temporary = File('$dbPath.copying');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(dbPath);
    }

    _db = await openDatabase(dbPath, readOnly: true);
  }

  Future<Verse?> getVerse(String book, int chapter, int verse) async {
    await verifyAndInit();
    final rows = await _db!.query(
      'verses',
      columns: ['book', 'chapter', 'verse', 'text'],
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Verse(
      book: r['book'] as String,
      chapter: r['chapter'] as int,
      verse: r['verse'] as int,
      text: r['text'] as String,
    );
  }

  Future<List<Verse>> getChapter(String book, int chapter) async {
    await verifyAndInit();
    final rows = await _db!.query(
      'verses',
      columns: ['book', 'chapter', 'verse', 'text'],
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse ASC',
    );
    return rows
        .map(
          (r) => Verse(
            book: r['book'] as String,
            chapter: r['chapter'] as int,
            verse: r['verse'] as int,
            text: r['text'] as String,
          ),
        )
        .toList();
  }

  Future<List<int>> getChapters(String book) async {
    await verifyAndInit();
    final rows = await _db!.rawQuery(
      'SELECT DISTINCT chapter FROM verses WHERE book = ? ORDER BY chapter ASC',
      [book],
    );
    return rows.map((r) => (r['chapter'] as int)).toList();
  }

  Future<List<Verse>> searchVerses(String query, {int limit = 60}) async {
    await verifyAndInit();
    final normalized = query.trim();
    if (normalized.length < 2) return const [];
    final rows = await _db!.query(
      'verses',
      columns: ['book', 'chapter', 'verse', 'text'],
      where: 'text LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'book ASC, chapter ASC, verse ASC',
      limit: limit,
    );
    return rows
        .map(
          (r) => Verse(
            book: r['book'] as String,
            chapter: r['chapter'] as int,
            verse: r['verse'] as int,
            text: r['text'] as String,
          ),
        )
        .toList();
  }

  Future<String?> getVerseText(String book, int chapter, int verse) async {
    final v = await getVerse(book, chapter, verse);
    return v?.text;
  }

  Future<List<Map<String, dynamic>>> getChapterMap(
    String book,
    int chapter,
  ) async {
    final verses = await getChapter(book, chapter);
    return verses.map((v) => {'verse': v.verse, 'text': v.text}).toList();
  }
}
