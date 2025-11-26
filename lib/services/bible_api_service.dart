import 'package:flutter/foundation.dart';
import '../models/verse.dart';
import 'verse_service.dart';

/// Servicio para conectar con APIs de versículos bíblicos
/// Implementa fallback a contenido local si la API falla
class BibleApiService {
  final VerseService _localService = VerseService();
  
  // TODO: Configurar estas variables cuando tengas API keys
  // ignore: unused_field
  static const String _apiBaseUrl = 'https://api.bible.example.com'; // URL de ejemplo
  // ignore: unused_field
  static const String _apiKey = ''; // API key aquí cuando esté disponible
  
  /// Obtiene un versículo del día desde la API o fallback local
  Future<Verse?> getTodayVerse() async {
    try {
      // TODO: Implementar llamada real a la API cuando esté disponible
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/verses/today?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   return Verse.fromJson(json.decode(response.body));
      // }
      
      // Por ahora, usar fallback local
      return await _getLocalFallback();
    } catch (e) {
      debugPrint('Error fetching verse from API: $e');
      // Fallback a contenido local
      return await _getLocalFallback();
    }
  }

  /// Obtiene un versículo por referencia desde la API o fallback local
  Future<Verse?> getVerseByReference(String book, int chapter, int verse) async {
    try {
      // TODO: Implementar llamada real a la API
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/verses/$book/$chapter/$verse?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   return Verse.fromJson(json.decode(response.body));
      // }
      
      return await _getLocalFallback();
    } catch (e) {
      debugPrint('Error fetching verse by reference from API: $e');
      return await _getLocalFallback();
    }
  }

  /// Obtiene versículos por tema desde la API o fallback local
  Future<List<Verse>> getVersesByTopic(String topic) async {
    try {
      // TODO: Implementar llamada real a la API
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/verses/topic/$topic?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((v) => Verse.fromJson(v)).toList();
      // }
      
      return await _getLocalVersesByTopic(topic);
    } catch (e) {
      debugPrint('Error fetching verses by topic from API: $e');
      return await _getLocalVersesByTopic(topic);
    }
  }

  /// Fallback: Obtiene versículo del día desde contenido local
  Future<Verse?> _getLocalFallback() async {
    try {
      return await _localService.getTodayVerse();
    } catch (e) {
      debugPrint('Error loading local verse: $e');
      return null;
    }
  }

  /// Fallback: Obtiene versículos por tema desde contenido local
  Future<List<Verse>> _getLocalVersesByTopic(String topic) async {
    try {
      final verses = await _localService.loadLocalVerses();
      // Por ahora retornar algunos versículos disponibles
      // En el futuro, se puede implementar búsqueda por tags o palabras clave
      return verses.take(5).toList();
    } catch (e) {
      debugPrint('Error loading local verses by topic: $e');
      return [];
    }
  }

  /// Verifica si la API está disponible
  Future<bool> isApiAvailable() async {
    // TODO: Implementar verificación real
    // try {
    //   final response = await http.get(
    //     Uri.parse('$_apiBaseUrl/health'),
    //     headers: {'Authorization': 'Bearer $_apiKey'},
    //   ).timeout(const Duration(seconds: 5));
    //   return response.statusCode == 200;
    // } catch (e) {
    //   return false;
    // }
    return false; // Por ahora siempre usar local
  }
}

