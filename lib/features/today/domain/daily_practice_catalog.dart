import '../../../controllers/missions_controller.dart';
import '../../../design_system/icons/verbum_icons.dart';

/// Práctica del día: rota por día del año para que todos vean la misma.
Mission dailyPracticeFor(DateTime date) {
  final practices = <Mission>[
    Mission(
      id: 'practice',
      title: 'Tres motivos para agradecer',
      description: 'Reconoce la presencia de Dios en lo sencillo.',
      icon: VerbumIcons.sparkle,
      durationMinutes: 2,
      content:
          'Haz una pausa y piensa en tres regalos que hayas recibido hoy. Pueden ser pequeños: una conversación, una oportunidad, un momento de calma.\n\nNómbralos uno por uno y di: “Gracias, Dios, por este regalo”.',
    ),
    Mission(
      id: 'practice',
      title: 'Ora por alguien',
      description: 'Pon delante de Dios a una persona que lo necesite.',
      icon: VerbumIcons.heart,
      durationMinutes: 2,
      content:
          'Piensa en una persona que esté atravesando una dificultad. Pronuncia su nombre en silencio y confía su vida a Dios.\n\nPide por su paz, su fortaleza y por aquello que más necesite en este momento.',
    ),
    Mission(
      id: 'practice',
      title: 'Un minuto de silencio',
      description: 'Deja el ruido y permanece un momento con Dios.',
      icon: VerbumIcons.flowerLotus,
      durationMinutes: 1,
      content:
          'Busca una postura cómoda, respira lentamente y permanece un minuto en silencio.\n\nNo necesitas encontrar palabras. Cuando aparezca una distracción, vuelve con calma a esta frase: “Aquí estoy, Señor”.',
    ),
    Mission(
      id: 'practice',
      title: 'Escribe una intención',
      description: 'Dale un nombre a lo que hoy llevas en el corazón.',
      icon: VerbumIcons.notePencil,
      durationMinutes: 2,
      content:
          'Detente y reconoce qué ocupa hoy tu corazón. Escríbelo en una frase breve en tus notas personales o en un papel.\n\nDespués entrégaselo a Dios con confianza: “Señor, pongo esta intención en tus manos”.',
    ),
    Mission(
      id: 'practice',
      title: 'Comparte una palabra de ánimo',
      description: 'Convierte la fe de hoy en cercanía para alguien.',
      icon: VerbumIcons.chatCircleText,
      durationMinutes: 3,
      content:
          'Piensa en alguien que necesite compañía o esperanza. Envíale un mensaje breve y sincero para recordarle que no está solo.\n\nNo hace falta dar consejos; basta con estar presente.',
    ),
    Mission(
      id: 'practice',
      title: 'Haz un gesto de bondad',
      description: 'Lleva la Palabra a una acción concreta.',
      icon: VerbumIcons.handHeart,
      durationMinutes: 3,
      content:
          'Elige un gesto sencillo que puedas realizar hoy: ayudar sin que te lo pidan, escuchar con paciencia, ceder tu lugar o agradecer de corazón.\n\nHazlo discretamente y ofrece ese gesto a Dios.',
    ),
    Mission(
      id: 'practice',
      title: 'Guarda una frase contigo',
      description: 'Elige una palabra del versículo para volver a ella hoy.',
      icon: VerbumIcons.bookmarkSimple,
      durationMinutes: 2,
      content:
          'Regresa mentalmente al versículo de hoy y elige la frase que más te haya tocado.\n\nRepítela lentamente tres veces. Déjala acompañarte durante el resto del día.',
    ),
    Mission(
      id: 'practice',
      title: 'Da un paso hacia la paz',
      description: 'Abre un espacio interior para perdonar o pedir perdón.',
      icon: VerbumIcons.handshake,
      durationMinutes: 3,
      content:
          'Piensa con serenidad si hoy puedes dar un pequeño paso hacia la reconciliación. Tal vez sea escuchar, reconocer un error o dejar de alimentar un resentimiento.\n\nNo necesitas resolverlo todo ahora. Pide a Dios la humildad y la sabiduría para comenzar.',
    ),
    Mission(
      id: 'practice',
      title: 'Ora por tu comunidad',
      description: 'Amplía tu oración hacia las necesidades de los demás.',
      icon: VerbumIcons.usersThree,
      durationMinutes: 2,
      content:
          'Recuerda a las personas que forman parte de tu comunidad, tu barrio o tu iglesia.\n\nPide por quienes están solos, enfermos o preocupados, y también por quienes sirven silenciosamente a los demás.',
    ),
  ];
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return practices[dayOfYear % practices.length];
}
