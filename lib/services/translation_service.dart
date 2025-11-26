import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'language_service.dart';

/// Servicio para traducir versículos y oraciones
/// Usa traducción automática cuando es necesario
class TranslationService {
  static const int _timeoutSeconds = 10;

  /// Traduce un texto al idioma especificado
  /// Usa múltiples métodos: API de traducción o diccionario interno
  Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;

    try {
      // Si el texto ya está en el idioma objetivo, retornarlo
      final currentLang = LanguageService.getLanguage();
      if (currentLang == targetLanguage) {
        return text;
      }

      // Intentar traducción usando API
      final translated = await _translateWithAPI(text, targetLanguage);
      if (translated.isNotEmpty && translated != text) {
        return translated;
      }

      // Fallback: usar diccionario de traducciones comunes
      return _translateWithDictionary(text, targetLanguage);
    } catch (e) {
      debugPrint('Error translating text: $e');
      return text; // Retornar texto original si falla
    }
  }

  /// Traduce usando API de traducción (MyMemory o similar)
  Future<String> _translateWithAPI(String text, String targetLanguage) async {
    try {
      // Usar API gratuita de MyMemory Translation
      final sourceLang = _detectLanguage(text);
      if (sourceLang == targetLanguage) return text;

      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$sourceLang|$targetLanguage',
      );

      final response = await http
          .get(url)
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseData'] != null &&
            data['responseData']['translatedText'] != null) {
          return data['responseData']['translatedText'] as String;
        }
      }
    } catch (e) {
      debugPrint('Error with translation API: $e');
    }
    return text;
  }

  /// Detecta el idioma del texto
  String _detectLanguage(String text) {
    // Detección simple basada en caracteres comunes
    if (RegExp(r'[áéíóúñÁÉÍÓÚÑ]').hasMatch(text)) {
      return 'es';
    } else if (RegExp(r'[ãõçÃÕÇ]').hasMatch(text)) {
      return 'pt';
    }
    return 'en';
  }

  /// Traduce usando diccionario interno de frases comunes
  String _translateWithDictionary(String text, String targetLanguage) {
    // Diccionario de traducciones comunes para versículos bíblicos
    final dictionary = _getTranslationDictionary();
    
    final lowerText = text.toLowerCase().trim();
    
    // Buscar traducción exacta
    if (dictionary.containsKey(lowerText)) {
      final translations = dictionary[lowerText];
      if (translations != null && translations.containsKey(targetLanguage)) {
        return translations[targetLanguage]!;
      }
    }

    // Buscar traducción parcial
    for (var entry in dictionary.entries) {
      if (lowerText.contains(entry.key) || entry.key.contains(lowerText)) {
        final translations = entry.value;
        if (translations.containsKey(targetLanguage)) {
          return translations[targetLanguage]!;
        }
      }
    }

    return text; // Retornar original si no se encuentra traducción
  }

  /// Diccionario de traducciones comunes
  Map<String, Map<String, String>> _getTranslationDictionary() {
    return {
      'for god so loved the world': {
        'es': 'Porque de tal manera amó Dios al mundo',
        'pt': 'Porque Deus amou o mundo de tal maneira',
      },
      'trust in the lord': {
        'es': 'Confía en el Señor',
        'pt': 'Confie no Senhor',
      },
      'i can do all things': {
        'es': 'Todo lo puedo',
        'pt': 'Posso todas as coisas',
      },
      'the lord is my shepherd': {
        'es': 'El Señor es mi pastor',
        'pt': 'O Senhor é o meu pastor',
      },
      'i know the plans': {
        'es': 'Yo sé los planes',
        'pt': 'Eu sei os planos',
      },
      'do not fear': {
        'es': 'No temas',
        'pt': 'Não temas',
      },
      'cast all your anxiety': {
        'es': 'Echad toda vuestra ansiedad',
        'pt': 'Lancem sobre ele toda a ansiedade',
      },
      'i am the way': {
        'es': 'Yo soy el camino',
        'pt': 'Eu sou o caminho',
      },
      'do not be anxious': {
        'es': 'Por nada estéis afanosos',
        'pt': 'Não se preocupem com nada',
      },
      'all things work together': {
        'es': 'Todas las cosas les ayudan a bien',
        'pt': 'Todas as coisas cooperam para o bem',
      },
    };
  }

  /// Traduce una referencia bíblica (ej: "John 3:16" -> "Juan 3:16")
  String translateReference(String reference, String targetLanguage) {
    if (targetLanguage == 'en') return reference;

    // Mapeo de nombres de libros bíblicos
    final bookMap = {
      'en': {
        'John': {'es': 'Juan', 'pt': 'João'},
        'Proverbs': {'es': 'Proverbios', 'pt': 'Provérbios'},
        'Philippians': {'es': 'Filipenses', 'pt': 'Filipenses'},
        'Psalms': {'es': 'Salmos', 'pt': 'Salmos'},
        'Jeremiah': {'es': 'Jeremías', 'pt': 'Jeremias'},
        'Isaiah': {'es': 'Isaías', 'pt': 'Isaías'},
        '1 Peter': {'es': '1 Pedro', 'pt': '1 Pedro'},
        'Romans': {'es': 'Romanos', 'pt': 'Romanos'},
        'Matthew': {'es': 'Mateo', 'pt': 'Mateus'},
        'Mark': {'es': 'Marcos', 'pt': 'Marcos'},
        'Luke': {'es': 'Lucas', 'pt': 'Lucas'},
        'Acts': {'es': 'Hechos', 'pt': 'Atos'},
        'Corinthians': {'es': 'Corintios', 'pt': 'Coríntios'},
        'Galatians': {'es': 'Gálatas', 'pt': 'Gálatas'},
        'Ephesians': {'es': 'Efesios', 'pt': 'Efésios'},
        'Colossians': {'es': 'Colosenses', 'pt': 'Colossenses'},
        'Thessalonians': {'es': 'Tesalonicenses', 'pt': 'Tessalonicenses'},
        'Timothy': {'es': 'Timoteo', 'pt': 'Timóteo'},
        'Titus': {'es': 'Tito', 'pt': 'Tito'},
        'Hebrews': {'es': 'Hebreos', 'pt': 'Hebreus'},
        'James': {'es': 'Santiago', 'pt': 'Tiago'},
        'Revelation': {'es': 'Apocalipsis', 'pt': 'Apocalipse'},
      },
    };

    try {
      for (var entry in bookMap['en']!.entries) {
        if (reference.contains(entry.key)) {
          final translation = entry.value[targetLanguage];
          if (translation != null) {
            return reference.replaceAll(entry.key, translation);
          }
        }
      }
    } catch (e) {
      debugPrint('Error translating reference: $e');
    }

    return reference;
  }
}

