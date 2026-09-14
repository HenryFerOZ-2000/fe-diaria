import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadAloudService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(.43);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  Future<void> speak(String text) async {
    try {
      await _configure();
      await _tts.stop();
      await _tts.speak(text);
    } catch (error) {
      debugPrint('[ReadAloudService] $error');
      rethrow;
    }
  }

  Future<void> stop() => _tts.stop();
}
