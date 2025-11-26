import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/verse.dart';
import 'language_service.dart';
import 'translation_service.dart';

/// Servicio para obtener versículos desde APIs externas
/// Prioriza versículos en español y usa APIs como último recurso
class ApiService {
  static const String _ourMannaApiUrl = 'https://beta.ourmanna.com/api/v1/get?format=json';
  static const int _timeoutSeconds = 10;

  final TranslationService _translationService = TranslationService();

  /// Obtiene un versículo desde la API y lo traduce al idioma del usuario
  /// NOTA: Las APIs disponibles devuelven versículos en inglés
  /// Este método traduce automáticamente al idioma configurado
  Future<Verse?> getDailyVerse() async {
    try {
      final targetLanguage = LanguageService.getLanguage();
      
      // Intentar primero con ourmanna.com
      final verse = await _getVerseFromOurManna();
      if (verse != null) {
        return await _translateVerse(verse, targetLanguage);
      }

      // Fallback a bible-api.com
      final verse2 = await _getVerseFromBibleApi();
      if (verse2 != null) {
        return await _translateVerse(verse2, targetLanguage);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting verse from API: $e');
      return null;
    }
  }

  /// Traduce un versículo al idioma objetivo
  Future<Verse> _translateVerse(Verse verse, String targetLanguage) async {
    try {
      // Traducir el texto del versículo
      final translatedText = await _translationService.translateText(
        verse.text,
        targetLanguage,
      );

      // Traducir la referencia
      final translatedReference = _translationService.translateReference(
        verse.reference,
        targetLanguage,
      );

      // Traducir el nombre del libro
      final translatedBook = _translationService.translateReference(
        verse.book,
        targetLanguage,
      );

      return Verse(
        id: verse.id,
        text: translatedText,
        reference: translatedReference,
        book: translatedBook.isNotEmpty ? translatedBook : verse.book,
        chapter: verse.chapter,
        verse: verse.verse,
      );
    } catch (e) {
      debugPrint('Error translating verse: $e');
      return verse; // Retornar versículo original si falla la traducción
    }
  }

  /// Obtiene versículo desde OurManna API (en inglés)
  Future<Verse?> _getVerseFromOurManna() async {
    try {
      final response = await http
          .get(Uri.parse(_ourMannaApiUrl))
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['verse'] != null && data['details'] != null) {
          final verseText = data['verse']['details']['text'] as String? ?? 
                          data['verse']['details']['reference'] as String? ?? '';
          final reference = data['verse']['details']['reference'] as String? ?? 
                          data['verse']['details']['text'] as String? ?? '';
          
          if (verseText.isNotEmpty) {
            final refParts = _parseReference(reference);
            
            return Verse(
              id: DateTime.now().millisecondsSinceEpoch,
              text: verseText.trim(),
              reference: reference.trim(),
              book: refParts['book'] ?? '',
              chapter: refParts['chapter'] ?? 0,
              verse: refParts['verse'] ?? 0,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting verse from OurManna: $e');
    }
    return null;
  }

  /// Obtiene versículo desde Bible API (en inglés)
  /// Usa versículos populares en español traducidos
  Future<Verse?> _getVerseFromBibleApi() async {
    try {
      // Mapeo de referencias en inglés a español
      final verseMap = {
        'john+3:16': {
          'text': 'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
          'reference': 'Juan 3:16',
          'book': 'Juan',
          'chapter': 3,
          'verse': 16,
        },
        'proverbs+3:5-6': {
          'text': 'Confía en el Señor de todo corazón, y no en tu propia inteligencia. Reconócelo en todos tus caminos, y él allanará tus sendas.',
          'reference': 'Proverbios 3:5-6',
          'book': 'Proverbios',
          'chapter': 3,
          'verse': 5,
        },
        'philippians+4:13': {
          'text': 'Todo lo puedo en Cristo que me fortalece.',
          'reference': 'Filipenses 4:13',
          'book': 'Filipenses',
          'chapter': 4,
          'verse': 13,
        },
        'psalms+23:1': {
          'text': 'El Señor es mi pastor, nada me faltará.',
          'reference': 'Salmos 23:1',
          'book': 'Salmos',
          'chapter': 23,
          'verse': 1,
        },
        'jeremiah+29:11': {
          'text': 'Porque yo sé los planes que tengo para ustedes —afirma el Señor—, planes de bienestar y no de calamidad, a fin de darles un futuro y una esperanza.',
          'reference': 'Jeremías 29:11',
          'book': 'Jeremías',
          'chapter': 29,
          'verse': 11,
        },
        'isaiah+41:10': {
          'text': 'No temas, porque yo estoy contigo; no desanimes, porque yo soy tu Dios. Te fortaleceré y te ayudaré; te sostendré con mi diestra victoriosa.',
          'reference': 'Isaías 41:10',
          'book': 'Isaías',
          'chapter': 41,
          'verse': 10,
        },
        '1peter+5:7': {
          'text': 'Echad toda vuestra ansiedad sobre él, porque él tiene cuidado de vosotros.',
          'reference': '1 Pedro 5:7',
          'book': '1 Pedro',
          'chapter': 5,
          'verse': 7,
        },
        'john+14:6': {
          'text': 'Jesús le dijo: Yo soy el camino, y la verdad, y la vida; nadie viene al Padre, sino por mí.',
          'reference': 'Juan 14:6',
          'book': 'Juan',
          'chapter': 14,
          'verse': 6,
        },
        'philippians+4:6': {
          'text': 'Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante de Dios en toda oración y ruego, con acción de gracias.',
          'reference': 'Filipenses 4:6',
          'book': 'Filipenses',
          'chapter': 4,
          'verse': 6,
        },
        'romans+8:28': {
          'text': 'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien, esto es, a los que conforme a su propósito son llamados.',
          'reference': 'Romanos 8:28',
          'book': 'Romanos',
          'chapter': 8,
          'verse': 28,
        },
      };

      // Lista de referencias populares
      final popularVerses = verseMap.keys.toList();

      // Usar la fecha para seleccionar un versículo diferente cada día
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final index = dayOfYear % popularVerses.length;
      final verseRef = popularVerses[index];
      final verseData = verseMap[verseRef];

      if (verseData != null) {
        return Verse(
          id: DateTime.now().millisecondsSinceEpoch,
          text: verseData['text'] as String,
          reference: verseData['reference'] as String,
          book: verseData['book'] as String,
          chapter: verseData['chapter'] as int,
          verse: verseData['verse'] as int,
        );
      }
    } catch (e) {
      debugPrint('Error getting verse from Bible API: $e');
    }
    return null;
  }

  /// Parsea una referencia bíblica para extraer libro, capítulo y versículo
  Map<String, dynamic> _parseReference(String reference) {
    try {
      // Formato típico: "Juan 3:16" o "Proverbios 3:5-6"
      final regex = RegExp(r'(\d*\s*[A-Za-záéíóúÁÉÍÓÚñÑ\s]+)\s+(\d+):(\d+)');
      final match = regex.firstMatch(reference);
      
      if (match != null) {
        return {
          'book': match.group(1)?.trim() ?? '',
          'chapter': int.tryParse(match.group(2) ?? '0') ?? 0,
          'verse': int.tryParse(match.group(3) ?? '0') ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Error parsing reference: $e');
    }
    
    return {'book': '', 'chapter': 0, 'verse': 0};
  }
}
