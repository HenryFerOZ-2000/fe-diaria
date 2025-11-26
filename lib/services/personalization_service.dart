import '../models/verse.dart';
import 'verse_service.dart';
import 'storage_service.dart';

/// Servicio para personalización de contenido basado en emociones y nombre del usuario
class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  final VerseService _verseService = VerseService();
  final StorageService _storageService = StorageService();

  // Mapeo de emociones a palabras clave para versículos (8 emociones simplificadas)
  final Map<String, List<String>> _emotionKeywords = {
    'ansioso': ['paz', 'tranquilidad', 'confianza', 'ansiedad', 'miedo'],
    'triste': ['consuelo', 'alegría', 'esperanza', 'tristeza', 'esperanza'],
    'cansado': ['descanso', 'fuerza', 'renovación', 'carga', 'cansancio'],
    'preocupado': ['preocupación', 'confianza', 'preocupaciones', 'carga'],
    'agradecido': ['gratitud', 'alabanza', 'bendición', 'agradecimiento'],
    'feliz': ['alegría', 'gozo', 'felicidad', 'bendición'],
    'confundido': ['sabiduría', 'guía', 'dirección', 'claridad', 'entendimiento'],
    'miedo': ['miedo', 'valentía', 'confianza', 'protección', 'seguridad'],
  };

  /// Obtiene la emoción actual del usuario
  String getUserEmotion() {
    return _storageService.getUserEmotion();
  }

  /// Obtiene el nombre del usuario
  String getUserName() {
    return _storageService.getUserName();
  }

  /// Genera una oración personalizada basada en el nombre y la emoción del usuario
  String generatePersonalizedPrayer(String emotion, String name) {
    if (name.isEmpty) {
      name = 'querido hermano/hermana';
    }

    // Si no hay emoción, usar oración por defecto
    if (emotion.isEmpty) {
      return _getDefaultPrayer(name);
    }

    final prayers = _getPrayersForEmotion(emotion, name);
    if (prayers.isEmpty) {
      return _getDefaultPrayer(name);
    }

    // Seleccionar una oración aleatoria basada en la emoción
    final random = DateTime.now().millisecondsSinceEpoch % prayers.length;
    return prayers[random];
  }

  /// Obtiene versículos recomendados basados en la emoción del usuario
  Future<List<Verse>> getVersesForEmotion(String emotion) async {
    final allVerses = await _verseService.loadLocalVerses();
    
    if (emotion.isEmpty || !_emotionKeywords.containsKey(emotion)) {
      return allVerses;
    }

    final keywords = _emotionKeywords[emotion]!;
    final matchingVerses = <Verse>[];

    // Buscar versículos que contengan las palabras clave
    for (final verse in allVerses) {
      final verseText = verse.text.toLowerCase();
      for (final keyword in keywords) {
        if (verseText.contains(keyword.toLowerCase())) {
          if (!matchingVerses.any((v) => v.id == verse.id)) {
            matchingVerses.add(verse);
          }
          break;
        }
      }
    }

    // Si no encontramos versículos específicos, retornar versículos generales de esperanza
    if (matchingVerses.isEmpty) {
      return allVerses.take(10).toList();
    }

    return matchingVerses;
  }

  /// Obtiene el versículo del día personalizado según la emoción
  Future<Verse> getPersonalizedVerse(String emotion) async {
    final verses = await getVersesForEmotion(emotion);
    
    if (verses.isEmpty) {
      return await _verseService.getTodayVerse();
    }

    // Seleccionar un versículo aleatorio basado en la fecha para mantener consistencia diaria
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final index = dayOfYear % verses.length;
    
    return verses[index];
  }

  /// Obtiene oraciones personalizadas para cada emoción
  List<String> _getPrayersForEmotion(String emotion, String name) {
    switch (emotion.toLowerCase()) {
      case 'ansioso':
        return [
          'Dios Padre, en este momento de ansiedad, $name clama a Ti pidiendo paz. Tu Palabra dice: "No se angustien por nada; más bien, en toda ocasión, con oración y ruego, presenten sus peticiones a Dios". Te pido que calmes el corazón de $name y le des la paz que sobrepasa todo entendimiento. Amén.',
          'Señor, $name está sintiendo ansiedad y preocupación. Te pido que le recuerdes que Tú estás a su lado en todo momento. Que sienta Tu presencia reconfortante y que encuentre descanso en Ti. Gracias por ser nuestro refugio y fortaleza. En el nombre de Jesús, Amén.',
          'Padre, mira el torbellino en el corazón de $name. Apaga el ruido de la prisa y enciende tu calma. Enséñale a respirar en tu presencia y a confiar en tu cuidado fiel. Amén.',
          'Señor de paz, guarda los pensamientos de $name. Que tu verdad sea muralla y tu amor descanso. Abrázale con serenidad mientras entrega sus cargas a Ti. Amén.',
          'Dios, cuando la incertidumbre apriete, recuérdale a $name que Tú gobiernas con bondad. Ordena su interior y dale ánimos para el día. Amén.',
          'Padre tierno, toma de la mano a $name. Camina a su ritmo, aquieta su alma y hazle sentir que no está solo/a. Tu presencia es refugio. Amén.',
          'Señor, sobre la ansiedad de $name, declara tu paz. Que en cada respiración encuentre descanso y en cada paso, confianza. Amén.',
          'Dios fiel, enséñale a $name a poner en Ti lo que no puede controlar. Dale serenidad para hoy y esperanza para mañana. Amén.',
          'Padre, levanta a $name por dentro. Que tu amor desactive el miedo y tu palabra gobierne sus pensamientos. Amén.',
          'Señor, que $name halle cobijo en tu abrazo. Sé su calma en la tormenta y su fuerza en la debilidad. Amén.',
        ];
      case 'triste':
        return [
          'Dios de consuelo, $name está pasando por un momento de tristeza. Tú eres el Padre de misericordia y Dios de toda consolación. Te pido que envuelvas a $name con Tu amor incondicional y que le muestres la esperanza que solo viene de Ti. Que encuentre gozo en Tu presencia. Amén.',
          'Padre celestial, $name necesita Tu consuelo en este momento de tristeza. Tu Palabra promete que Tú estás cerca de los de corazón quebrantado. Acércate a $name, Señor, y límpiale las lágrimas con Tu amor. Que Tu paz llene su corazón. Amén.',
          'Señor, acaricia el corazón de $name con tu ternura. Donde hay lágrimas, siembra esperanza; donde hay vacío, habita tú. Amén.',
          'Padre, recuerda a $name que no camina solo/a. Tu compañía es medicina, tu palabra, consuelo. Sostén su alma cansada. Amén.',
          'Dios, en la noche de $name, enciende una luz. Que tu amor alivie la pena y renueve la fuerza por dentro. Amén.',
          'Señor, recoge los pedazos del ánimo de $name y reconstruye con tu paz. Dale descanso y un motivo para sonreír. Amén.',
          'Padre, toma con cuidado las heridas de $name. Sana con tu bondad y pon tu canto suave en su interior. Amén.',
          'Dios de toda gracia, levanta a $name. Que tu abrazo sea real y tu consuelo, profundo. Amén.',
          'Señor, cambia la pesadez por liviandad y el llanto por sosiego en $name. Tu presencia baste hoy. Amén.',
        ];
      case 'agradecido':
        return [
          'Dios de toda bondad, $name quiere expresar gratitud por todas Tus bendiciones. Gracias por Tu amor incesante, por Tu cuidado constante y por las innumerables bendiciones que has derramado en la vida de $name. Que su corazón siempre esté lleno de alabanza y acción de gracias. Amén.',
          'Padre misericordioso, $name está agradecido por Tu fidelidad. Te alabamos porque eres bueno y Tu misericordia es para siempre. Que $name siempre recuerde Tus bondades y viva en gratitud constante hacia Ti. Bendito seas, Señor. Amén.',
          'Señor, recibe la gratitud de $name por la vida, la paz y tu guía. Que cada detalle sea motivo de alabanza. Amén.',
          'Padre, ensancha el corazón agradecido de $name. Que recuerde tus beneficios y camine alegre. Amén.',
          'Dios, gracias por las pequeñas luces de este día. Que $name viva con ojos de gratitud. Amén.',
          'Señor, que la gratitud de $name sea testimonio de tu bondad. Hazle cantar aun en lo sencillo. Amén.',
          'Padre, gracias por tu cuidado fiel. Que $name aprenda a agradecer antes de pedir. Amén.',
          'Dios, multiplica en $name el gozo de agradecer. Que tu paz custodie su interior. Amén.',
          'Señor, toda buena dádiva viene de Ti. $name te reconoce y te honra. Amén.',
        ];
      case 'motivado':
        return [
          'Dios de poder y fuerza, $name está lleno de motivación y desea alcanzar grandes cosas para Tu gloria. Te pido que le des la sabiduría, el valor y la perseverancia necesarios. Que cada paso que dé sea guiado por Tu Espíritu y que todo lo que haga sea para honrarte. Amén.',
          'Señor Todopoderoso, $name siente motivación y ganas de avanzar. Te pido que fortalezcas sus manos para la obra, que le des visión clara de Tus propósitos y que cada esfuerzo sea bendecido por Ti. Que $name sepa que puede hacer todas las cosas en Cristo que le fortalece. Amén.',
          'Padre, ordena la energía de $name para lo que edifica. Dale claridad en los objetivos y constancia diaria. Amén.',
          'Dios, abre la puerta correcta y cierra la que no conviene. Que $name avance contigo. Amén.',
          'Señor, afirma los pasos de $name y humilde su corazón. Que la motivación sea servicio y no vanidad. Amén.',
          'Padre, fortalece la paciencia de $name. Que no se rinda en el bien y espere en tu tiempo. Amén.',
          'Dios, renueva la visión de $name. Que trabaje con excelencia y esperanza. Amén.',
          'Señor, guía la mente y las manos de $name. Que su esfuerzo dé fruto para bien. Amén.',
          'Padre, protege a $name del desánimo. Sopla aliento nuevo y enfoque claro. Amén.',
        ];
      case 'preocupado':
        return [
          'Dios de paz, $name tiene preocupaciones en su corazón. Tu Palabra nos instruye a echar todas nuestras preocupaciones sobre Ti. Toma las cargas de $name, Señor, y dale Tu paz que sobrepasa todo entendimiento. Confía en Ti, que eres fiel. Amén.',
          'Padre amoroso, $name está cargando preocupaciones que no debería llevar solo. Te pido que le ayudes a soltar todas sus ansiedades en Tus manos y a confiar completamente en Tu provisión. Que $name encuentre descanso sabiendo que Tú cuidas de él/ella. Amén.',
          'Señor, toma lo que pesa en $name. Enséñale a confiar paso a paso. Que tu paz gobierne su interior. Amén.',
          'Padre, cuando el futuro inquiete a $name, recuérdale tu fidelidad de ayer. Tú no cambias. Amén.',
          'Dios, guarda la mente de $name de escenarios de temor. Enciende esperanza sobria y real. Amén.',
          'Señor, hoy $name elige dejar la carga en tus manos. Dale descanso y claridad. Amén.',
          'Padre, abre caminos de bien y cierra puertas de angustia. Dirige a $name con tu luz. Amén.',
          'Dios, regala a $name respiraciones de paz y pensamientos de verdad. Amén.',
          'Señor, que $name encuentre en Ti refugio seguro y ánimo renovado. Amén.',
        ];
      case 'feliz':
        return [
          'Dios de alegría, $name está lleno de felicidad y quiere compartir esta bendición contigo. Te agradecemos por los momentos de gozo y por permitirnos experimentar Tu bondad. Que $name siempre recuerde que Tú eres la fuente de toda verdadera alegría. Amén.',
          'Señor de gozo, $name experimenta felicidad y quiere agradecerte por todas Tus bendiciones. Que esta alegría sea compartida con otros y que siempre apunte hacia Ti como la fuente de toda bendición. Que el gozo del Señor sea la fortaleza de $name. Amén.',
          'Padre, que el gozo de $name sea luz para otros. Humilde y contagioso, fruto de tu bondad. Amén.',
          'Dios, guarda el corazón alegre de $name de la soberbia. Que su alegría te honre. Amén.',
          'Señor, gracias por esta dicha. Enséñale a $name a celebrar con sencillez y gratitud. Amén.',
          'Padre, que el gozo de $name se convierta en servicio. Que bendiga a quien lo rodea. Amén.',
          'Dios, multiplica la gratitud en medio de la alegría. Hazla memoria de tu amor. Amén.',
          'Señor, que el gozo fortalezca a $name para el bien de cada día. Amén.',
          'Padre, conserva en $name un corazón agradecido y generoso. Amén.',
        ];
      case 'desanimado':
        return [
          'Dios de ánimo, $name se siente desanimado y necesita Tu fortaleza. Te pido que renueves su esperanza, que le recuerdes Tus promesas y que le des el ánimo necesario para continuar. Que $name encuentre nueva fuerza en Tu presencia. Amén.',
          'Padre de consolación, $name está pasando por un momento de desánimo. Te pido que le muestres Tu luz en medio de la oscuridad, que le des esperanza renovada y que le recuerdes que contigo siempre hay una razón para continuar. Fortalece a $name, Señor. Amén.',
          'Señor, levanta el ánimo de $name. Una palabra tuya basta para encender su esperanza. Amén.',
          'Padre, recuerda a $name tus promesas. Que su corazón tome aliento en tu fidelidad. Amén.',
          'Dios, cuando las fuerzas mengüen, sé sostén de $name. Dale paso pequeño pero firme. Amén.',
          'Señor, pon un canto suave en el interior de $name y renueva su alegría. Amén.',
          'Padre, rodea a $name de buenas voces y buenos amigos. Que no camine solo/a. Amén.',
          'Dios, que $name vuelva a intentarlo contigo. En tu nombre, esperanza. Amén.',
          'Señor, que hoy haya una señal de tu amor que reanime a $name. Amén.',
        ];
      case 'enojado':
        return [
          'Dios de paz, $name está luchando con sentimientos de enojo. Te pido que le des la paz que solo Tú puedes dar, que le ayudes a perdonar como Tú perdonas y que Tu amor llene su corazón. Que $name encuentre serenidad en Tu presencia. Amén.',
          'Señor de misericordia, $name necesita Tu ayuda para manejar el enojo. Te pido que le des paciencia, comprensión y un corazón lleno de Tu amor. Que $name recuerde que el amor es paciente y bondadoso, y que Tu gracia es suficiente. Amén.',
          'Padre, enfría la reacción y calienta la comprensión en $name. Enséñale a responder con mansedumbre. Amén.',
          'Dios, limpia el corazón de $name de resentimiento. Que el perdón abra camino a la paz. Amén.',
          'Señor, dale a $name palabras suaves y firmes, y silencios que sanen. Amén.',
          'Padre, que la ira no gobierne el día de $name. Pon dominio propio y serenidad. Amén.',
          'Dios, muéstrale a $name tu mirada sobre la situación y suelta la tensión interior. Amén.',
          'Señor, guarda a $name del juicio apresurado. Regálale empatía y calma. Amén.',
          'Padre, que triunfe la paz en el corazón de $name. Amén.',
        ];
      case 'cansado':
        return [
          'Dios de descanso, $name está cansado y necesita Tu fuerza renovadora. Tu Palabra dice: "Venid a mí todos los que estáis trabajados y cargados, y yo os haré descansar". Te pido que renueves las fuerzas de $name y que encuentre descanso en Ti. Que Tu paz llene su corazón. Amén.',
          'Padre celestial, $name está agotado y necesita Tu renovación. Te pido que le des descanso físico y espiritual, que restaures sus fuerzas y que encuentre refugio en Tu presencia. Que $name confíe en que Tú le darás las fuerzas necesarias. Amén.',
          'Señor, toma el peso que lleva $name. Dale un descanso que restaure y una paz que permanezca. Amén.',
          'Padre, renueva las fuerzas de $name como del águila. Que hoy recobre aliento. Amén.',
          'Dios, enséñale a $name a detenerse contigo, a respirar en tu presencia. Amén.',
          'Señor, calma la mente de $name y relaja su cuerpo. Pon sosiego profundo. Amén.',
          'Padre, que el descanso de $name sea semilla de un nuevo ánimo. Amén.',
          'Dios, tú eres su refugio. Permite a $name dormir bien y despertar renovado/a. Amén.',
          'Señor, reduce el ruido y aumenta la paz en el interior de $name. Amén.',
        ];
      case 'confundido':
        return [
          'Dios de sabiduría, $name está confundido y necesita Tu dirección. Tu Palabra promete que si pedimos sabiduría, Tú la darás generosamente. Te pido que guíes los pasos de $name, que le muestres el camino correcto y que le des claridad en sus decisiones. Amén.',
          'Señor de toda verdad, $name necesita Tu guía en este momento de confusión. Te pido que le des entendimiento, que ilumines su camino y que le muestres Tu voluntad. Que $name confíe en que Tú le guiarás por el mejor camino. Amén.',
          'Padre, disipa la niebla en la mente de $name. Enciende tu luz y señala el próximo paso. Amén.',
          'Dios, que $name no tema detenerse para escuchar. Háblale claro y suave. Amén.',
          'Señor, rodea a $name de buenos consejos. Afirma su corazón en tu verdad. Amén.',
          'Padre, ordena las opciones y muestra lo que conviene. Da paz a $name. Amén.',
          'Dios, guía a $name con tu palabra. Que no se pierda en lo urgente y siga lo importante. Amén.',
          'Señor, abre camino en el desorden y regala serenidad para decidir. Amén.',
          'Padre, que $name sienta tu compañía en cada decisión. Amén.',
        ];
      case 'miedo':
        return [
          'Dios de valentía, $name está sintiendo miedo y necesita Tu protección. Tu Palabra dice: "No temas, porque yo estoy contigo". Te pido que envuelvas a $name con Tu amor perfecto que echa fuera el temor, y que le recuerdes que Tú estás con él/ella siempre. Amén.',
          'Padre protector, $name está experimentando miedo y necesita Tu presencia tranquilizadora. Te pido que le des valor y confianza, que le muestres Tu fidelidad y que encuentre seguridad en Tu amor. Que $name sepa que está seguro/a en Tus manos. Amén.',
          'Señor, abraza el temor de $name con tu amor perfecto. Que la valentía nazca de tu presencia. Amén.',
          'Padre, apaga los fantasmas de la mente y enciende verdad en $name. Amén.',
          'Dios, guarda a $name de lo que no ve y fortalece su fe en Ti. Amén.',
          'Señor, que $name recuerde: no está solo/a. Tú caminas con él/ella. Amén.',
          'Padre, cambia sobresalto por confianza, y angustia por paz en $name. Amén.',
          'Dios, rodea a $name con tu protección y descanso. Amén.',
          'Señor, enséñale a $name a respirar tu paz y avanzar sin temor. Amén.',
        ];
      default:
        return [_getDefaultPrayer(name)];
    }
  }

  /// Obtiene una oración por defecto
  String _getDefaultPrayer(String name) {
    return 'Dios Padre, bendice a $name en este día. Guía sus pasos, protege su camino y llénalo de Tu amor y paz. Que Tu presencia sea constante en su vida y que siempre camine en Tus caminos. Amén.';
  }
}

