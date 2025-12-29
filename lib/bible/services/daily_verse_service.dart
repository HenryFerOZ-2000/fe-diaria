import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/bible_db.dart';
import '../domain/verse.dart';

class DailyVerseService {
  DailyVerseService._();
  static final DailyVerseService _instance = DailyVerseService._();
  factory DailyVerseService() => _instance;

  List<Map<String, dynamic>>? _refs;

  Future<void> _loadRefs() async {
    if (_refs != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/daily_verses_refs.json');
    final List<dynamic> data = json.decode(jsonStr);
    _refs = data.map((e) => e as Map<String, dynamic>).toList();
  }

  int _indexForDate(DateTime date, int length) {
    final yyyymmdd = date.year * 10000 + date.month * 100 + date.day;
    return yyyymmdd % length;
  }

  Future<Verse> getDailyVerse({DateTime? date}) async {
    await _loadRefs();
    await BibleDb.instance.verifyAndInit();
    if (_refs == null || _refs!.isEmpty) {
      throw Exception('No hay referencias de versículos diarias cargadas');
    }

    final now = date ?? DateTime.now();
    final idx = _indexForDate(now, _refs!.length);
    final ref = _refs![idx];
    final book = ref['book'] as String;
    final chapter = ref['chapter'] as int;
    final verseNum = ref['verse'] as int;
    final tag = ref['tag'] as String?;

    final text = await BibleDb.instance.getVerseText(book, chapter, verseNum);
    if (text == null) {
      throw Exception('No se encontró el versículo $book $chapter:$verseNum en la DB');
    }
    return Verse(
      book: book,
      chapter: chapter,
      verse: verseNum,
      text: text,
      tag: tag,
    );
  }
}

