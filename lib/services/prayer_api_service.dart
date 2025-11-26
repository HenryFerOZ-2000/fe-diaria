import 'package:flutter/foundation.dart';
import '../models/prayer.dart';

/// Servicio para obtener oraciones desde APIs externas
/// Incluye fallback a oraciones locales si la API falla
class PrayerApiService {

  // Oraciones de respaldo locales
  static final List<Map<String, String>> _localPrayers = [
    {
      'title': 'Oración de la Mañana',
      'text': 'Señor, te doy gracias por este nuevo día. Guía mis pasos y bendice todas mis acciones. Que tu luz ilumine mi camino y que tu amor llene mi corazón. Amén.',
      'type': 'morning',
    },
    {
      'title': 'Oración de la Mañana',
      'text': 'Dios mío, al comenzar este día, pongo mi confianza en ti. Ayúdame a ser una bendición para los demás y a vivir según tu voluntad. Amén.',
      'type': 'morning',
    },
    {
      'title': 'Oración de la Mañana',
      'text': 'Padre celestial, gracias por el regalo de un nuevo día. Que tu presencia me acompañe en cada momento y que mi vida sea un testimonio de tu amor. Amén.',
      'type': 'morning',
    },
    {
      'title': 'Oración de la Noche',
      'text': 'Señor, al finalizar este día, te agradezco por todas las bendiciones recibidas. Perdona mis errores y dame descanso en tu paz. Amén.',
      'type': 'evening',
    },
    {
      'title': 'Oración de la Noche',
      'text': 'Dios mío, antes de dormir, encomiendo mi vida en tus manos. Protégeme durante la noche y renueva mis fuerzas para el día que viene. Amén.',
      'type': 'evening',
    },
    {
      'title': 'Oración de la Noche',
      'text': 'Padre, gracias por este día que termina. Que tu paz llene mi corazón y que pueda descansar confiando en tu cuidado. Amén.',
      'type': 'evening',
    },
  ];

  /// Obtiene una oración del día
  /// Usa la API si está disponible, sino usa oraciones locales
  Future<Prayer> getDailyPrayer({required String type}) async {
    try {
      // Intentar obtener desde API (si está disponible)
      final prayer = await _getPrayerFromApi(type: type);
      if (prayer != null) return prayer;
    } catch (e) {
      debugPrint('Error getting prayer from API: $e');
    }

    // Fallback a oraciones locales
    return _getLocalPrayer(type: type);
  }

  /// Intenta obtener oración desde API
  Future<Prayer?> _getPrayerFromApi({required String type}) async {
    try {
      // Por ahora, usamos oraciones locales ya que no hay una API pública confiable
      // Este método está preparado para cuando haya una API disponible
      return null;
    } catch (e) {
      debugPrint('Error fetching prayer from API: $e');
      return null;
    }
  }

  /// Obtiene una oración local basada en la fecha
  Prayer _getLocalPrayer({required String type}) {
    final prayers = _localPrayers.where((p) => p['type'] == type).toList();
    
    if (prayers.isEmpty) {
      // Si no hay oraciones del tipo solicitado, usar la primera disponible
      final defaultPrayer = _localPrayers.first;
      return Prayer(
        id: DateTime.now().millisecondsSinceEpoch,
        text: defaultPrayer['text'] ?? '',
        type: type,
        title: defaultPrayer['title'] ?? 'Oración',
      );
    }

    // Usar la fecha para seleccionar una oración diferente cada día
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % prayers.length;
    final prayerData = prayers[index];

    return Prayer(
      id: DateTime.now().millisecondsSinceEpoch + (type == 'morning' ? 0 : 1000),
      text: prayerData['text'] ?? '',
      type: type,
      title: prayerData['title'] ?? 'Oración',
    );
  }

  /// Obtiene todas las oraciones locales disponibles
  List<Prayer> getAllLocalPrayers() {
    return _localPrayers.map((p) => Prayer(
      id: _localPrayers.indexOf(p),
      text: p['text'] ?? '',
      type: p['type'] ?? 'morning',
      title: p['title'] ?? 'Oración',
    )).toList();
  }
}

