import 'dart:convert';
import 'package:flutter/services.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final Map<String, Map<String, dynamic>> _bookCache = {};

  Future<List<String>> getBooks() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
    final bibleFiles = manifestMap.keys
        .where((k) => k.startsWith('assets/bible/') && k.endsWith('.json'))
        .toList();
    bibleFiles.sort();
    return bibleFiles
        .map((path) => path.split('/').last.replaceAll('.json', ''))
        .toList();
  }

  Future<Map<String, dynamic>> loadBook(String book) async {
    if (_bookCache.containsKey(book)) return _bookCache[book]!;
    final path = 'assets/bible/$book.json';
    final raw = await rootBundle.loadString(path);
    final data = json.decode(raw) as Map<String, dynamic>;
    _bookCache[book] = data;
    return data;
  }

  Future<List<String>> loadChapter(String book, int chapter) async {
    final data = await loadBook(book);
    final chapters = data['chapters'] as List<dynamic>;
    if (chapter < 1 || chapter > chapters.length) return [];
    final verses = chapters[chapter - 1] as List<dynamic>;
    return verses.map((v) => v.toString()).toList();
  }

  Future<int> getChaptersCount(String book) async {
    final data = await loadBook(book);
    final chapters = data['chapters'] as List<dynamic>;
    return chapters.length;
  }
}

