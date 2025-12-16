import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/helloao_models.dart';

class HelloAoBibleApi {
  HelloAoBibleApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://bible.helloao.org/api';
  static const _translationKey = 'selected_translation_id';
  static const _cacheTtlDays = 7;

  Future<List<HelloAoTranslation>> fetchAvailableTranslations() async {
    final uri = Uri.parse('$_baseUrl/available_translations.json');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error al obtener traducciones (${res.statusCode})');
    }
    final data = json.decode(res.body) as List<dynamic>;
    return data
        .map((e) => HelloAoTranslation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchBooks(String translationId) async {
    final uri = Uri.parse('$_baseUrl/$translationId/books.json');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error al obtener libros (${res.statusCode})');
    }
    final data = json.decode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<HelloAoChapter> fetchChapter(
    String translationId,
    String bookId,
    int chapterNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey(translationId, bookId, chapterNumber);
    final cacheTimeKey = '${cacheKey}_time';

    HelloAoChapter? fromCache() {
      final cached = prefs.getString(cacheKey);
      if (cached == null) return null;
      try {
        final jsonMap = json.decode(cached) as Map<String, dynamic>;
        return HelloAoChapter.fromJson(jsonMap);
      } catch (_) {
        return null;
      }
    }

    bool cacheValid() {
      final timeMs = prefs.getInt(cacheTimeKey);
      if (timeMs == null) return false;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timeMs);
      return DateTime.now().difference(cachedAt).inDays < _cacheTtlDays;
    }

    if (cacheValid()) {
      final chapter = fromCache();
      if (chapter != null) return chapter;
    }

    final uri =
        Uri.parse('$_baseUrl/$translationId/$bookId/$chapterNumber.json');
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Error HTTP ${res.statusCode}');
      }
      final jsonMap = json.decode(res.body) as Map<String, dynamic>;
      final chapter = HelloAoChapter.fromJson(jsonMap);
      await prefs.setString(cacheKey, res.body);
      await prefs.setInt(
          cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      return chapter;
    } catch (_) {
      final cached = fromCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<String> getOrSelectTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_translationKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final translations = await fetchAvailableTranslations();
    final spa = translations.where((t) {
      final lang = t.language?.toLowerCase() ?? '';
      final langName = t.languageName?.toLowerCase() ?? '';
      final langEn = t.languageEnglishName?.toLowerCase() ?? '';
      return lang == 'spa' ||
          langName.contains('españ') ||
          langEn.contains('spanish');
    }).toList();

    final pick = spa.firstWhere(
      (t) =>
          t.name.toLowerCase().contains('reina') ||
          t.name.toLowerCase().contains('valera') ||
          (t.englishName ?? '').toLowerCase().contains('reina') ||
          (t.englishName ?? '').toLowerCase().contains('valera'),
      orElse: () => spa.isNotEmpty ? spa.first : translations.first,
    );

    final chosen = pick;
    await prefs.setString(_translationKey, chosen.id);
    return chosen.id;
  }

  Future<void> setSelectedTranslation(String translationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationKey, translationId);
  }

  String _cacheKey(String translationId, String bookId, int chapter) =>
      'cache_${translationId}_$bookId\_$chapter';
}

