import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:hive_flutter/hive_flutter.dart';

/// Servicio para gestionar el idioma de la aplicación
/// Detecta automáticamente el idioma del sistema
/// Soporta Español, Inglés y Portugués
class LanguageService {
  static const String _languageBoxName = 'language_settings';
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'es';

  static Box? _box;
  static String? _systemLanguage;

  /// Inicializa el servicio de idioma y detecta el idioma del sistema
  static Future<void> init() async {
    try {
      _box = await Hive.openBox(_languageBoxName);
      _detectSystemLanguage();
    } catch (e) {
      debugPrint('Error initializing language service: $e');
    }
  }

  /// Detecta el idioma del sistema
  static void _detectSystemLanguage() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final languageCode = locale.languageCode.toLowerCase();
      
      // Mapear códigos de idioma a nuestros códigos soportados
      if (languageCode == 'es' || languageCode.startsWith('es')) {
        _systemLanguage = 'es';
      } else if (languageCode == 'pt' || languageCode.startsWith('pt')) {
        _systemLanguage = 'pt';
      } else if (languageCode == 'en' || languageCode.startsWith('en')) {
        _systemLanguage = 'en';
      } else {
        _systemLanguage = _defaultLanguage; // Fallback a español
      }
    } catch (e) {
      debugPrint('Error detecting system language: $e');
      _systemLanguage = _defaultLanguage;
    }
  }

  /// Obtiene el idioma actual (manual o automático del sistema)
  static String getLanguage() {
    try {
      // Si el usuario ha seleccionado manualmente un idioma, usarlo
      if (_box != null && _box!.containsKey(_languageKey)) {
        return _box!.get(_languageKey) as String;
      }
      
      // Si no, usar el idioma del sistema detectado
      if (_systemLanguage != null) {
        return _systemLanguage!;
      }
      
      // Si no se pudo detectar, detectar ahora
      _detectSystemLanguage();
      return _systemLanguage ?? _defaultLanguage;
    } catch (e) {
      debugPrint('Error getting language: $e');
      return _defaultLanguage;
    }
  }

  /// Guarda el idioma seleccionado
  static Future<void> setLanguage(String languageCode) async {
    try {
      if (_box != null) {
        await _box!.put(_languageKey, languageCode);
      }
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Verifica si el usuario ha seleccionado manualmente un idioma
  static bool hasManualLanguageSelected() {
    try {
      return _box != null && _box!.containsKey(_languageKey);
    } catch (e) {
      return false;
    }
  }

  /// Resetea el idioma para usar el del sistema
  static Future<void> resetToSystemLanguage() async {
    try {
      if (_box != null) {
        await _box!.delete(_languageKey);
      }
      _detectSystemLanguage();
    } catch (e) {
      debugPrint('Error resetting to system language: $e');
    }
  }

  /// Obtiene el nombre del idioma en su propio idioma
  static String getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      default:
        return 'Español';
    }
  }

  /// Obtiene el nombre del idioma en el idioma actual
  static String getLanguageNameTranslated(String code, String currentLang) {
    if (currentLang == 'es') {
      switch (code) {
        case 'es':
          return 'Español';
        case 'en':
          return 'Inglés';
        case 'pt':
          return 'Portugués';
        default:
          return 'Español';
      }
    } else if (currentLang == 'pt') {
      switch (code) {
        case 'es':
          return 'Espanhol';
        case 'en':
          return 'Inglês';
        case 'pt':
          return 'Português';
        default:
          return 'Português';
      }
    } else {
      // English
      switch (code) {
        case 'es':
          return 'Spanish';
        case 'en':
          return 'English';
        case 'pt':
          return 'Portuguese';
        default:
          return 'English';
      }
    }
  }
}

