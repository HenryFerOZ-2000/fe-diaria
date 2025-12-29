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
  static const String _dbName = 'rv1909.sqlite';

  Database? _db;
  Completer<void>? _copying;

  Future<void> verifyAndInit() async {
    // Verificar que el asset exista
    try {
      await rootBundle.load(_assetPath);
    } catch (_) {
      throw Exception('No se encontró el asset $_assetPath. Asegúrate de que el archivo exista y esté declarado en pubspec.yaml.');
    }
    await init();
  }

  Future<void> init() async {
    if (_db != null) return;
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbName);

    final file = File(dbPath);
    if (!await file.exists()) {
      // Evitar copias concurrentes en arranque
      _copying ??= Completer<void>();
      if (!_copying!.isCompleted) {
        try {
          await file.parent.create(recursive: true);
          final data = await rootBundle.load(_assetPath);
          final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await file.writeAsBytes(bytes, flush: true);
          _copying!.complete();
        } catch (e) {
          _copying!.completeError(e);
          rethrow;
        }
      }
      await _copying!.future;
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
    return rows
        .map((r) => (r['chapter'] as int))
        .toList();
  }

  Future<String?> getVerseText(String book, int chapter, int verse) async {
    final v = await getVerse(book, chapter, verse);
    return v?.text;
  }

  Future<List<Map<String, dynamic>>> getChapterMap(String book, int chapter) async {
    final verses = await getChapter(book, chapter);
    return verses
        .map((v) => {
              'verse': v.verse,
              'text': v.text,
            })
        .toList();
  }
}

