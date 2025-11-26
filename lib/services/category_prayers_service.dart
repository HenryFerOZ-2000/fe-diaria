import '../models/verse.dart';
import 'verse_service.dart';

/// Servicio para oraciones por categorías (no usa el nombre del usuario)
class CategoryPrayersService {
  static final CategoryPrayersService _instance = CategoryPrayersService._internal();
  factory CategoryPrayersService() => _instance;
  CategoryPrayersService._internal();

  final VerseService _verseService = VerseService();

  // Lista de categorías públicas (clave -> título visible)
  Map<String, String> get categories => const {
        'familia': 'Mi familia',
        'salud': 'Mi salud',
        'trabajo': 'Mi trabajo',
        'finanzas': 'Mis finanzas',
        'hogar': 'Mi hogar',
        'proteccion': 'Mi protección',
        'descanso': 'Mi descanso',
        'mente': 'Mi mente / paz',
        'animo': 'Mi ánimo',
        'agradecimiento': 'Mi agradecimiento',
      };

  // Conjunto de oraciones variadas por categoría (mínimo 4-6 para rotar)
  static final Map<String, List<String>> _categoryPrayers = {
    'familia': [
      'Señor, pongo en tus manos mi familia. Cúbrenos con tu amor y danos unidad en todo tiempo. Amén.',
      'Padre, bendice nuestro hogar. Enséñanos a perdonar y a caminar en tu paz. Amén.',
      'Dios, protege la vida de cada uno en mi familia. Que tu cuidado sea nuestro refugio. Amén.',
      'Señor, danos sabiduría para hablar con amor y construir juntos. Amén.',
      'Padre, haz de nuestro hogar un lugar de esperanza, fe y alegría. Amén.',
      'Señor, guarda nuestras relaciones y sana lo que esté herido en mi familia. Amén.',
      'Padre bueno, que en nuestra mesa abunden la gratitud y la paz. Amén.',
      'Dios, afirmamos nuestra casa en tu palabra; sé fundamento y techo. Amén.',
      'Señor, enséñanos a escucharnos con paciencia y a amarnos con respeto. Amén.',
      'Padre, cubre a mi familia con tu protección y guíanos en tu verdad. Amén.',
      'Dios, que tu alegría nos visite y tu luz nos sostenga cada día. Amén.',
    ],
    'salud': [
      'Padre, restaura mi salud y fortalece mi cuerpo. Dame calma en medio de la dificultad. Amén.',
      'Señor, dame fuerzas nuevas. Trae sanidad y descanso a mi vida. Amén.',
      'Dios, guía a quienes me atienden y renueva mi ánimo cada día. Amén.',
      'Señor, que tu paz llene mi mente y tu poder obre en mi cuerpo. Amén.',
      'Padre, en tus manos pongo mi salud; confío en tu fidelidad. Amén.',
      'Señor, alivia el dolor y aumenta la esperanza mientras espero en Ti. Amén.',
      'Padre, fortalece mi ánimo y ayúdame a descansar bien esta noche. Amén.',
      'Dios, que el tratamiento sea eficaz y mi corazón permanezca en paz. Amén.',
      'Señor, renueva mi mente para vencer la ansiedad y confiar en Ti. Amén.',
      'Padre, dame paciencia en el proceso y gratitud por cada avance. Amén.',
    ],
    'trabajo': [
      'Dios, bendice mi trabajo. Abre puertas y dame favor con las personas correctas. Amén.',
      'Señor, enséñame a ser diligente y a honrarte con lo que hago. Amén.',
      'Padre, dame creatividad y sabiduría para resolver cada desafío. Amén.',
      'Señor, dirige mis pasos y muéstrame nuevas oportunidades. Amén.',
      'Dios, que mi esfuerzo produzca fruto y bendición. Amén.',
      'Padre, guarda mis relaciones laborales y dame buen carácter. Amén.',
      'Señor, ayúdame a trabajar con excelencia y corazón íntegro. Amén.',
      'Dios, abre caminos justos y cierra puertas que no convienen. Amén.',
      'Padre, sostén mi ánimo en las metas y dame constancia diaria. Amén.',
      'Señor, que mi trabajo sea servicio y reflejo de tu bondad. Amén.',
    ],
    'finanzas': [
      'Señor, enséñame a administrar bien lo que me das. Suple lo necesario. Amén.',
      'Dios, abre caminos de provisión y quita toda preocupación. Amén.',
      'Padre, dame orden, disciplina y generosidad con lo que tengo. Amén.',
      'Señor, aleja la escasez y guía mis decisiones económicas. Amén.',
      'Dios, agradezco tu provisión y confío en tu cuidado. Amén.',
      'Padre, muéstrame cómo sembrar con sabiduría y vivir con contentamiento. Amén.',
      'Señor, cuida mis entradas y salidas; guarda mi corazón de la avaricia. Amén.',
      'Dios, dame oportunidades honestas y manos diligentes para avanzar. Amén.',
      'Padre, líbrame de decisiones impulsivas y guíame con tu paz. Amén.',
      'Señor, hazme generoso y sensible a la necesidad ajena. Amén.',
    ],
    'hogar': [
      'Señor, cuida mi hogar y llénalo de tu paz. Amén.',
      'Padre, que en casa se respire amor, respeto y esperanza. Amén.',
      'Dios, protege nuestra entrada y salida cada día. Amén.',
      'Señor, que en nuestro hogar reine tu presencia y tu luz. Amén.',
      'Padre, guarda nuestras relaciones y fortalece nuestros lazos. Amén.',
      'Señor, que cada conversación edifique y cada gesto sea de bondad. Amén.',
      'Padre, ordena nuestras prioridades y enséñanos a descansar en Ti. Amén.',
      'Dios, que nuestra mesa sea lugar de gratitud y comunión. Amén.',
      'Señor, haz de este hogar un refugio de paz y esperanza. Amén.',
      'Padre, que tu amor sea cimiento y tu verdad, dirección. Amén.',
    ],
    'proteccion': [
      'Padre, te pido tu protección. Líbrame de peligros y guíame con tu luz. Amén.',
      'Señor, rodea mi vida con tus ángeles y dame sabiduría para elegir bien. Amén.',
      'Dios, guarda mis caminos hoy y siempre. Eres mi refugio seguro. Amén.',
      'Señor, aleja todo mal y fortalece mi corazón en tu paz. Amén.',
      'Padre, descanso en tu cobertura y en tu cuidado fiel. Amén.',
      'Señor, guarda mis pensamientos del temor y mis pasos del tropiezo. Amén.',
      'Dios, sé muro de fuego a mi alrededor y paz en mi interior. Amén.',
      'Padre, que tu mano me guíe con firmeza y ternura. Amén.',
      'Señor, líbrame de todo mal visible e invisible. Amén.',
      'Dios, sello este día bajo tu amparo y tu verdad. Amén.',
    ],
    'descanso': [
      'Señor, dame descanso y renueva mis fuerzas. Que tu paz me acompañe. Amén.',
      'Padre, calma mi mente y mi corazón para dormir en tranquilidad. Amén.',
      'Dios, tomo tu paz y dejo mis cargas en tus manos. Amén.',
      'Señor, gracias por este día; dame un sueño reparador. Amén.',
      'Padre, que al despertar encuentre nuevas fuerzas en ti. Amén.',
      'Señor, apaga la ansiedad y enciende la confianza antes de dormir. Amén.',
      'Padre, régálame un sueño profundo que restaure cuerpo y alma. Amén.',
      'Dios, que tu presencia sea abrigo suave durante la noche. Amén.',
      'Señor, aquieta mi interior y dame sosiego en tu paz. Amén.',
      'Padre, en tus manos confío mi descanso. Amén.',
    ],
    'mente': [
      'Dios, guarda mi mente y dame tu paz. Silencia la ansiedad en mí. Amén.',
      'Señor, llena mis pensamientos de esperanza y verdad. Amén.',
      'Padre, renueva mi manera de pensar para vivir confiando en ti. Amén.',
      'Dios, quita la confusión y dame claridad para decidir. Amén.',
      'Señor, dame serenidad y enfoque para este día. Amén.',
      'Padre, aleja la preocupación y siembra calma en mi interior. Amén.',
      'Dios, que tu verdad guarde mis pensamientos de la mentira. Amén.',
      'Señor, ordena mis ideas y dirige mis pasos con tu paz. Amén.',
      'Padre, hazme perseverante y descansado por dentro. Amén.',
      'Dios, dame pensamientos de bien y esperanza viva. Amén.',
    ],
    'animo': [
      'Padre, fortalece mi ánimo. Levántame con tu palabra y tu amor. Amén.',
      'Señor, renueva mi esperanza y dame gozo para seguir. Amén.',
      'Dios, dame valentía para enfrentar lo que viene. Amén.',
      'Señor, quita el desánimo y lléname de tu fortaleza. Amén.',
      'Padre, confío en tus promesas y en tu fidelidad. Amén.',
      'Señor, levanta mi mirada y enciende en mí tu alegría. Amén.',
      'Padre, cuando flaquee, recuérdame tu fidelidad de siempre. Amén.',
      'Dios, llena mi interior de aliento nuevo y paz firme. Amén.',
      'Señor, restaura mi gozo y hazme constante en la esperanza. Amén.',
      'Padre, que tu amor me haga fuerte hoy. Amén.',
    ],
    'agradecimiento': [
      'Señor, gracias por tus bondades. Reconozco tu fidelidad hoy. Amén.',
      'Padre, te agradezco por lo que tengo y por lo que viene. Amén.',
      'Dios, quiero vivir con un corazón agradecido cada día. Amén.',
      'Señor, gracias por tu amor, cuidado y provisión. Amén.',
      'Padre, aun en lo pequeño, encuentro motivos para agradecer. Amén.',
      'Señor, despierta en mí la gratitud que honra tu nombre. Amén.',
      'Padre, gracias por tu presencia, tu paz y tu guía diaria. Amén.',
      'Dios, quiero nombrar tus bondades y vivir agradecido/a. Amén.',
      'Señor, que la gratitud sea mi canción en todo tiempo. Amén.',
      'Padre, gracias por tu cuidado fiel de cada día. Amén.',
    ],
  };

  /// Genera una oración para la categoría indicada (dirigida a Dios, con pertenencia "mi/mis")
  String getPrayerForCategory(String categoryKey) {
    final list = _categoryPrayers[categoryKey];
    if (list == null || list.isEmpty) {
      return 'Señor, pongo esta área de mi vida en tus manos. Muéstrame tu voluntad, sostén mi corazón y guía mis pasos con tu luz. Amén.';
    }
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(start).inDays; // 0-based
    final index = list.isEmpty ? 0 : dayOfYear % list.length;
    return list[index];
  }

  /// Obtiene un versículo sugerido para la categoría (heurística simple por palabras clave)
  Future<Verse> getSuggestedVerse(String categoryKey) async {
    final verses = await _verseService.loadLocalVerses();
    final keywords = _keywordsForCategory(categoryKey);

    for (final verse in verses) {
      final t = verse.text.toLowerCase();
      for (final k in keywords) {
        if (t.contains(k)) {
          return verse;
        }
      }
    }

    // Fallback: versículo del día
    return _verseService.getTodayVerse();
  }

  /// Obtiene un versículo sugerido considerando el texto específico de la oración mostrada
  Future<Verse> getSuggestedVerseForPrayer(String categoryKey, String prayerText) async {
    final verses = await _verseService.loadLocalVerses();
    if (verses.isEmpty) {
      return _verseService.getTodayVerse();
    }

    final baseKeywords = _keywordsForCategory(categoryKey).toSet();
    final prayerKeywords = _extractKeywordsFromPrayer(prayerText);
    final allKeywords = {...baseKeywords, ...prayerKeywords};

    int bestScore = -1;
    Verse? best;

    for (final verse in verses) {
      final t = verse.text.toLowerCase();
      int score = 0;

      // Coincidencias por palabra clave
      for (final k in allKeywords) {
        if (k.isEmpty) continue;
        if (t.contains(k)) score += 3; // peso mayor para coincidencia exacta
      }

      // Bonus por sinónimos simples por categoría
      for (final syn in _synonymsForCategory(categoryKey)) {
        if (t.contains(syn)) score += 2;
      }

      // Si el verso tiene el mismo tema implícito por palabras comunes del text
      for (final k in prayerKeywords) {
        if (k.length > 5 && t.contains(k)) score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        best = verse;
      }
    }

    if (best != null && bestScore > 0) {
      return best;
    }

    // Si no hubo buena coincidencia, usar heurística por categoría
    return getSuggestedVerse(categoryKey);
  }

  List<String> _keywordsForCategory(String categoryKey) {
    switch (categoryKey) {
      case 'familia':
        return ['familia', 'hogar', 'casa', 'hijos', 'espos'];
      case 'salud':
        return ['sanidad', 'salud', 'curar', 'sanar', 'fortaleza'];
      case 'trabajo':
        return ['trabajo', 'obra', 'manos', 'diligencia'];
      case 'finanzas':
        return ['provisión', 'proveer', 'necesidad', 'bendición'];
      case 'hogar':
        return ['casa', 'hogar', 'morada', 'paz'];
      case 'proteccion':
        return ['proteger', 'protección', 'amparo', 'refugio'];
      case 'descanso':
        return ['descanso', 'paz', 'reposo', 'tranquilidad'];
      case 'mente':
        return ['mente', 'pensamientos', 'paz', 'ansiedad'];
      case 'animo':
        return ['ánimo', 'esperanza', 'fuerza', 'aliento'];
      case 'agradecimiento':
        return ['gracias', 'gratitud', 'alabanza', 'bondad'];
      default:
        return ['paz', 'esperanza'];
    }
  }

  List<String> _synonymsForCategory(String categoryKey) {
    switch (categoryKey) {
      case 'familia':
        return ['parentes', 'doméstic', 'unidad', 'amor'];
      case 'salud':
        return ['sanidad', 'curación', 'restauración', 'fuerza'];
      case 'trabajo':
        return ['labor', 'oficio', 'diligencia', 'obra'];
      case 'finanzas':
        return ['provisión', 'abundancia', 'necesidad', 'pan'];
      case 'hogar':
        return ['morada', 'habitación', 'paz', 'seguridad'];
      case 'proteccion':
        return ['amparo', 'refugio', 'escudo', 'guarda'];
      case 'descanso':
        return ['reposo', 'quietud', 'sosiego', 'paz'];
      case 'mente':
        return ['pensamientos', 'ansiedad', 'claridad', 'entendimiento'];
      case 'animo':
        return ['aliento', 'gozo', 'fuerza', 'fortaleza'];
      case 'agradecimiento':
        return ['gratitud', 'alabanza', 'acción de gracias'];
      default:
        return ['paz', 'esperanza'];
    }
  }

  /// Extrae palabras clave del texto de la oración (muy simple, filtrando stopwords)
  Set<String> _extractKeywordsFromPrayer(String text) {
    final stopwords = <String>{
      'el','la','los','las','un','una','unos','unas','y','o','u','de','del','al','a','ante','bajo','cabe','con','contra','desde','durante','en','entre','hacia','hasta','mediante','para','por','según','sin','so','sobre','tras',
      'mi','mis','me','mío','mía','míos','mías','tu','tus','tuyo','tuya','suyo','suya','sus','nuestro','nuestra','nuestros','nuestras',
      'que','como','porque','pero','si','sí','no','más','menos','muy','ya','hoy','cada','este','esta','estos','estas','ese','esa','esos','esas','aquel','aquella','aquellos','aquellas',
      'señor','padre','dios','amén'
    };
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúñü\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w.length > 3 && !stopwords.contains(w))
        .map((w) => _stemEs(w))
        .toSet();
    return normalized;
  }

  /// Stem rudimentario para español (recorta sufijos comunes)
  String _stemEs(String w) {
    var s = w;
    for (final suf in ['mente','ción','ciones','sión','siones','idades','idad','amente','mente','es','s','ar','er','ir','ando','endo','ado','ido']) {
      if (s.endsWith(suf) && s.length > suf.length + 3) {
        s = s.substring(0, s.length - suf.length);
        break;
      }
    }
    return s;
  }
}
