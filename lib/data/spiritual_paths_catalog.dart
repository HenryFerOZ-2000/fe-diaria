import 'package:flutter/material.dart';

import '../models/spiritual_path.dart';

class SpiritualPathsCatalog {
  static const paths = <SpiritualPath>[
    SpiritualPath(
      id: 'volver_a_confiar',
      title: 'Volver a confiar',
      subtitle: '7 días para descansar lo que pesa',
      description:
          'Un camino sereno para entregar el control, reconocer la presencia de Dios y recuperar la esperanza paso a paso.',
      category: 'Paz y confianza',
      minutesPerDay: 5,
      icon: Icons.spa_outlined,
      accent: Color(0xFF6B7398),
      days: [
        SpiritualPathDay(
          number: 1,
          title: 'No tienes que poder con todo',
          subtitle: 'Comienza soltando',
          scriptureReference: 'Mateo 11:28',
          scripture:
              'Venid a mí todos los que estáis trabajados y cargados, que yo os haré descansar.',
          reflection:
              'La fe no comienza cuando ya tienes fuerzas, sino cuando te permites llegar a Dios tal como estás. Tu cansancio no es un fracaso; también puede ser una puerta al descanso.',
          prayer:
              'Jesús, hoy llego sin respuestas. Recibe lo que me pesa y enséñame a descansar en tu presencia.',
          practice:
              'Nombra en silencio una carga y di: «Hoy no tengo que llevarla a solas». Mi vida no depende solo de mis fuerzas.',
        ),
        SpiritualPathDay(
          number: 2,
          title: 'Dios permanece cerca',
          subtitle: 'Reconoce su compañía',
          scriptureReference: 'Salmo 34:18',
          scripture: 'Cercano está Jehová a los quebrantados de corazón.',
          reflection:
              'El dolor suele hacernos sentir aislados. La Escritura no promete una vida sin heridas, pero sí una presencia que no abandona.',
          prayer:
              'Dios cercano, ayúdame a percibirte incluso cuando mis emociones no pueden encontrarte.',
          practice:
              'Haz una pausa de un minuto. Respira lentamente y repite: «Estás aquí». Cerca de mí, incluso ahora.',
        ),
        SpiritualPathDay(
          number: 3,
          title: 'Un día a la vez',
          subtitle: 'Regresa al presente',
          scriptureReference: 'Mateo 6:34',
          scripture:
              'No os congojéis por el día de mañana; que el día de mañana traerá su fatiga.',
          reflection:
              'La preocupación intenta vivir muchos días al mismo tiempo. La gracia, en cambio, llega para el día que realmente estás viviendo.',
          prayer:
              'Padre, dame la gracia necesaria para hoy y libertad para dejar el mañana en tus manos.',
          practice:
              'Elige una sola tarea importante para hoy. Hazla con atención y deja el resto para su momento. Mi paso de hoy es suficiente.',
        ),
        SpiritualPathDay(
          number: 4,
          title: 'Recuerda lo que ya sostuvo',
          subtitle: 'Haz memoria agradecida',
          scriptureReference: 'Lamentaciones 3:22-23',
          scripture: 'Nuevas son cada mañana; grande es tu fidelidad.',
          reflection:
              'Recordar no elimina la dificultad, pero nos devuelve una historia más completa: también has sido sostenido antes.',
          prayer:
              'Gracias por las veces que me sostuviste sin que yo supiera cómo seguir.',
          practice:
              'Escribe tres momentos en los que recibiste ayuda, consuelo o una salida inesperada. Tu fidelidad también está en mi historia.',
        ),
        SpiritualPathDay(
          number: 5,
          title: 'Confía mientras avanzas',
          subtitle: 'La claridad puede llegar caminando',
          scriptureReference: 'Proverbios 3:5',
          scripture:
              'Fíate de Jehová de todo tu corazón, y no estribes en tu prudencia.',
          reflection:
              'Confiar no significa entenderlo todo. Significa dar el siguiente paso honesto sin exigir ver el camino completo.',
          prayer:
              'Guía mi siguiente paso. Dame humildad para no necesitar controlar cada resultado.',
          practice:
              'Realiza hoy esa acción pequeña que has estado posponiendo por miedo. Tú ves el camino que yo todavía no veo.',
        ),
        SpiritualPathDay(
          number: 6,
          title: 'Recibe la paz',
          subtitle: 'No tienes que fabricarla',
          scriptureReference: 'Juan 14:27',
          scripture: 'La paz os dejo, mi paz os doy.',
          reflection:
              'La paz de Jesús no depende de que todo esté resuelto. Puede habitar en medio de preguntas todavía abiertas.',
          prayer:
              'Jesús, permite que tu paz llegue a los lugares de mí que siguen tensos y asustados.',
          practice:
              'Relaja conscientemente hombros, manos y mandíbula. Respira cuatro veces sin prisa. Recibo la paz que no puedo fabricar.',
        ),
        SpiritualPathDay(
          number: 7,
          title: 'Camina con esperanza',
          subtitle: 'Mira hacia adelante',
          scriptureReference: 'Romanos 15:13',
          scripture:
              'Y el Dios de esperanza os llene de todo gozo y paz creyendo.',
          reflection:
              'La esperanza cristiana no niega la realidad; afirma que la realidad no termina en lo que hoy alcanzas a ver.',
          prayer:
              'Dios de esperanza, haz de mi vida un lugar donde tu paz pueda crecer y alcanzar a otros.',
          practice:
              'Comparte una palabra de ánimo con alguien que la necesite. Camino acompañado y puedo acompañar.',
        ),
      ],
    ),
    SpiritualPath(
      id: 'paz_para_la_ansiedad',
      title: 'Paz para la ansiedad',
      subtitle: '7 días para respirar y permanecer',
      description:
          'Prácticas breves de oración, respiración y Escritura para atravesar los días de inquietud con compañía.',
      category: 'Bienestar espiritual',
      minutesPerDay: 4,
      icon: Icons.air_rounded,
      accent: Color(0xFF5F8178),
      days: [
        SpiritualPathDay(
          number: 1,
          title: 'Respira: estás aquí',
          subtitle: 'Vuelve a este momento',
          scriptureReference: 'Salmo 46:10',
          scripture: 'Estad quietos, y conoced que yo soy Dios.',
          reflection:
              'La quietud no exige que desaparezcan todos tus pensamientos. Solo te invita a dejar de correr detrás de cada uno.',
          prayer:
              'Dios, encuentra mi mente inquieta y llévame suavemente al presente.',
          practice:
              'Inhala durante cuatro segundos y exhala durante seis. Repite cinco veces diciendo: «Aquí estás». Este momento tiene gracia suficiente.',
        ),
        SpiritualPathDay(
          number: 2,
          title: 'Ponle nombre',
          subtitle: 'Habla con honestidad',
          scriptureReference: 'Salmo 62:8',
          scripture:
              'Derramad delante de él vuestro corazón: Dios es nuestro amparo.',
          reflection:
              'Lo que puedes nombrar deja de gobernarte desde la sombra. Dios no necesita una versión ordenada de lo que sientes.',
          prayer:
              'Te entrego mi inquietud sin adornarla. Recíbeme con verdad y ternura.',
          practice:
              'Completa la frase: «Ahora mismo temo que…». Luego añade: «Y no estoy solo». Puedo ser honesto delante de ti.',
        ),
        SpiritualPathDay(
          number: 3,
          title: 'Cuida tu atención',
          subtitle: 'Elige dónde permanecer',
          scriptureReference: 'Filipenses 4:8',
          scripture:
              'Todo lo verdadero, todo lo honesto, todo lo justo... en esto pensad.',
          reflection:
              'No controlas cada pensamiento que aparece, pero puedes elegir cuál alimentar y cuál dejar pasar.',
          prayer:
              'Ordena mi atención y ayúdame a reconocer lo verdadero entre tantas posibilidades.',
          practice:
              'Aléjate diez minutos de una fuente de ruido y observa algo sencillo y real a tu alrededor. Vuelvo a lo verdadero.',
        ),
        SpiritualPathDay(
          number: 4,
          title: 'Pide lo que necesitas',
          subtitle: 'La oración también es concreta',
          scriptureReference: 'Filipenses 4:6',
          scripture:
              'Sean notorias vuestras peticiones delante de Dios en toda oración y ruego.',
          reflection:
              'Presentar una necesidad no obliga a tener palabras perfectas. Una petición sencilla también puede ser una oración completa.',
          prayer:
              'Hoy necesito ayuda con aquello que tú ya conoces. Muéstrame también a quién puedo pedir apoyo.',
          practice:
              'Escribe una petición concreta y, si es posible, compártela con una persona de confianza. Pedir ayuda también es valentía.',
        ),
        SpiritualPathDay(
          number: 5,
          title: 'Habita tu cuerpo',
          subtitle: 'Tu cuerpo también ora',
          scriptureReference: '1 Corintios 6:19',
          scripture: 'Vuestro cuerpo es templo del Espíritu Santo.',
          reflection:
              'El cuidado espiritual no ocurre fuera del cuerpo. Descanso, alimento, movimiento y respiración también sostienen tu vida interior.',
          prayer: 'Enséñame a tratar mi cuerpo con paciencia y gratitud.',
          practice:
              'Bebe agua, camina cinco minutos o descansa sin pantalla. Elige lo que tu cuerpo necesita hoy. También te encuentro aquí.',
        ),
        SpiritualPathDay(
          number: 6,
          title: 'No anticipes la tormenta',
          subtitle: 'Distingue hechos de temores',
          scriptureReference: 'Isaías 41:10',
          scripture:
              'No temas, que yo soy contigo; no desmayes, que yo soy tu Dios.',
          reflection:
              'La ansiedad presenta posibilidades como si ya fueran hechos. La verdad puede ser más pequeña, pero también más firme.',
          prayer:
              'Ayúdame a distinguir lo que está ocurriendo de aquello que solamente temo.',
          practice:
              'Divide una hoja en «lo que sé» y «lo que imagino». Escribe sin juzgarte. Tu presencia es más firme que mis suposiciones.',
        ),
        SpiritualPathDay(
          number: 7,
          title: 'Construye un refugio',
          subtitle: 'Conserva lo aprendido',
          scriptureReference: 'Salmo 91:1',
          scripture:
              'El que habita al abrigo del Altísimo, morará bajo la sombra del Omnipotente.',
          reflection:
              'Un refugio interior se construye con prácticas pequeñas repetidas con amor, no con un único momento extraordinario.',
          prayer:
              'Haz de mi vida un lugar de encuentro contigo cuando vuelva la inquietud.',
          practice:
              'Elige una práctica de esta semana para repetir durante los próximos siete días. Tengo un lugar al que volver.',
        ),
      ],
    ),
    SpiritualPath(
      id: 'gratitud_cotidiana',
      title: 'Gratitud cotidiana',
      subtitle: '7 días para reconocer el regalo',
      description:
          'Entrena una mirada agradecida sin negar las dificultades y descubre la presencia de Dios en lo sencillo.',
      category: 'Vida diaria',
      minutesPerDay: 3,
      icon: Icons.wb_sunny_outlined,
      accent: Color(0xFFB58A45),
      days: [
        SpiritualPathDay(
          number: 1,
          title: 'Mira de nuevo',
          subtitle: 'Lo sencillo también habla',
          scriptureReference: 'Salmo 118:24',
          scripture:
              'Este es el día que hizo Jehová; nos gozaremos y alegraremos en él.',
          reflection:
              'La gratitud comienza cuando dejamos de atravesar el día como si todo fuera automático.',
          prayer: 'Abre mis ojos para reconocer la vida que hoy me entregas.',
          practice:
              'Fotografía o escribe sobre una cosa sencilla que normalmente das por sentada. Hoy recibo este día.',
        ),
        SpiritualPathDay(
          number: 2,
          title: 'Agradece a una persona',
          subtitle: 'El bien también tiene rostro',
          scriptureReference: 'Filipenses 1:3',
          scripture: 'Doy gracias a mi Dios en toda memoria de vosotros.',
          reflection:
              'Muchas bendiciones llegan a través de personas concretas. Nombrarlas evita que el bien se vuelva invisible.',
          prayer:
              'Gracias por quienes han sido compañía, paciencia y ayuda en mi historia.',
          practice:
              'Envía un mensaje específico de agradecimiento a alguien. El bien recibido puede seguir circulando.',
        ),
        SpiritualPathDay(
          number: 3,
          title: 'Recibe tu cuerpo',
          subtitle: 'Agradece lo que te permite vivir',
          scriptureReference: 'Salmo 139:14',
          scripture:
              'Te alabaré; porque formidables, maravillosas son tus obras.',
          reflection:
              'Tu cuerpo no es solamente algo que corregir. También es el lugar desde el que amas, trabajas, descansas y oras.',
          prayer:
              'Gracias por mi cuerpo real, con sus capacidades, límites e historia.',
          practice:
              'Agradece conscientemente una capacidad de tu cuerpo y cuídala hoy. Mi vida encarnada también es regalo.',
        ),
        SpiritualPathDay(
          number: 4,
          title: 'Encuentra gracia en lo difícil',
          subtitle: 'Sin negar el dolor',
          scriptureReference: 'Romanos 8:28',
          scripture:
              'A los que a Dios aman, todas las cosas les ayudan a bien.',
          reflection:
              'Agradecer no significa llamar bueno a todo. Significa buscar la gracia que sigue acompañándote dentro de lo difícil.',
          prayer:
              'No quiero negar lo que duele; muéstrame la ayuda que también está presente.',
          practice:
              'Nombra una dificultad y después una fuerza, persona o aprendizaje que te sostiene dentro de ella. La dificultad no cuenta toda la historia.',
        ),
        SpiritualPathDay(
          number: 5,
          title: 'Comparte lo recibido',
          subtitle: 'La gratitud se vuelve generosa',
          scriptureReference: '2 Corintios 9:7',
          scripture: 'Dios ama el dador alegre.',
          reflection:
              'Cuando reconocemos que hemos recibido, aparece el deseo de convertirnos también en regalo.',
          prayer:
              'Dame un corazón generoso, atento a las necesidades pequeñas que puedo aliviar.',
          practice:
              'Comparte hoy tiempo, atención o un recurso sin esperar reconocimiento. Lo recibido puede dar fruto.',
        ),
        SpiritualPathDay(
          number: 6,
          title: 'Celebra tu recorrido',
          subtitle: 'Reconoce cuánto has avanzado',
          scriptureReference: '1 Samuel 7:12',
          scripture: 'Hasta aquí nos ayudó Jehová.',
          reflection:
              'A veces miramos tanto lo pendiente que olvidamos la distancia ya recorrida.',
          prayer:
              'Gracias por cada paso, incluso por aquellos que parecían demasiado pequeños.',
          practice:
              'Escribe algo que ahora haces mejor que hace un año. Hasta aquí también fui sostenido.',
        ),
        SpiritualPathDay(
          number: 7,
          title: 'Haz de la gratitud un ritmo',
          subtitle: 'Continúa después del camino',
          scriptureReference: '1 Tesalonicenses 5:18',
          scripture: 'Dad gracias en todo; porque esta es la voluntad de Dios.',
          reflection:
              'La gratitud no tiene que ser intensa para ser verdadera. Necesita un lugar habitual dentro de tus días.',
          prayer:
              'Que mi gratitud no sea una obligación, sino una manera de reconocer tu presencia.',
          practice:
              'Elige un momento fijo del día para nombrar tres regalos durante la próxima semana. Quiero seguir mirando con atención.',
        ),
      ],
    ),
    SpiritualPath(
      id: 'dormir_en_paz',
      title: 'Dormir en paz',
      subtitle: '7 noches para entregar el día',
      description:
          'Una rutina nocturna de Escritura, examen sereno y oración para cerrar el día sin llevarlo entero a la cama.',
      category: 'Descanso',
      minutesPerDay: 6,
      icon: Icons.nightlight_round,
      accent: Color(0xFF77649A),
      days: [
        SpiritualPathDay(
          number: 1,
          title: 'El día puede terminar',
          subtitle: 'Da permiso al descanso',
          scriptureReference: 'Salmo 4:8',
          scripture:
              'En paz me acostaré, y asimismo dormiré; porque solo tú, Jehová, me harás estar confiado.',
          reflection:
              'Descansar es aceptar que el mundo puede continuar unas horas sin tu vigilancia.',
          prayer:
              'Recibe este día como fue. Guarda mi descanso y aquello que dejo pendiente.',
          practice:
              'Escribe lo pendiente en una lista para mañana y cierra la nota. Por hoy, es suficiente.',
        ),
        SpiritualPathDay(
          number: 2,
          title: 'Suelta la conversación',
          subtitle: 'No la repitas toda la noche',
          scriptureReference: 'Efesios 4:26',
          scripture: 'No se ponga el sol sobre vuestro enojo.',
          reflection:
              'Hay conversaciones que necesitan reparación, pero la madrugada rara vez ofrece la claridad para resolverlas.',
          prayer:
              'Dame paz para descansar y sabiduría para hablar mañana con amor.',
          practice:
              'Nombra la conversación que repites y di: «La retomaré con luz y calma». Esta noche la dejo contigo.',
        ),
        SpiritualPathDay(
          number: 3,
          title: 'Recorre el día con Dios',
          subtitle: 'Reconoce consuelo y dificultad',
          scriptureReference: 'Salmo 139:23',
          scripture: 'Examíname, oh Dios, y conoce mi corazón.',
          reflection:
              'Mirar el día con Dios no es evaluarte con dureza, sino descubrir dónde hubo vida y dónde necesitas cuidado.',
          prayer: 'Muéstrame este día con verdad, misericordia y sin condena.',
          practice:
              'Recuerda un momento de paz y uno de tensión. Agradece el primero y entrega el segundo. Todo mi día cabe en tu mirada.',
        ),
        SpiritualPathDay(
          number: 4,
          title: 'Perdona tu límite',
          subtitle: 'No todo quedó hecho',
          scriptureReference: '2 Corintios 12:9',
          scripture:
              'Bástate mi gracia; porque mi potencia en la flaqueza se perfecciona.',
          reflection:
              'Tu valor no depende de terminar cada tarea. La gracia también te encuentra incompleto.',
          prayer:
              'Perdóname por medir mi vida solo por productividad. Enséñame a recibir mi límite.',
          practice:
              'Di en voz baja algo que hoy no lograste y añade: «Eso no disminuye mi dignidad». Tu gracia completa lo que yo no puedo.',
        ),
        SpiritualPathDay(
          number: 5,
          title: 'Calma tu espacio',
          subtitle: 'Prepara el cuerpo para descansar',
          scriptureReference: 'Marcos 6:31',
          scripture:
              'Venid vosotros aparte al lugar desierto, y reposad un poco.',
          reflection:
              'El descanso necesita señales. La luz, el ruido y la pantalla le enseñan al cuerpo si todavía debe permanecer alerta.',
          prayer: 'Bendice este espacio y conviértelo en lugar de reposo.',
          practice:
              'Reduce la luz y deja el teléfono lejos durante los próximos diez minutos. Me aparto para reposar.',
        ),
        SpiritualPathDay(
          number: 6,
          title: 'Entrega a quienes amas',
          subtitle: 'No tienes que vigilarlos',
          scriptureReference: 'Salmo 121:4',
          scripture:
              'He aquí, no se adormecerá ni dormirá el que guarda a Israel.',
          reflection:
              'Amar a alguien no significa sostenerlo con preocupación constante. Puedes encomendarlo a un cuidado mayor que el tuyo.',
          prayer:
              'Cuida a las personas que amo mientras descanso. Dales lo que esta noche yo no puedo darles.',
          practice:
              'Nombra a cada persona que te preocupa y repite: «También está en tus manos». Tú permaneces despierto.',
        ),
        SpiritualPathDay(
          number: 7,
          title: 'Descansa como acto de fe',
          subtitle: 'Confía la noche',
          scriptureReference: 'Salmo 127:2',
          scripture: 'A su amado dará Dios el sueño.',
          reflection:
              'Dormir es una práctica cotidiana de confianza: sueltas la conciencia y recibes nuevamente la vida al despertar.',
          prayer:
              'Gracias por la semana que termina. Recibo el sueño como un regalo y no como una tarea.',
          practice:
              'Repite lentamente la oración del primer día hasta quedarte en silencio. En paz me acostaré.',
        ),
      ],
    ),
  ];

  static SpiritualPath byId(String id) =>
      paths.firstWhere((path) => path.id == id, orElse: () => paths.first);

  static SpiritualPath recommend({required int hour, String? emotion}) {
    if (hour >= 20 || hour < 5) return byId('dormir_en_paz');
    final normalized = emotion?.toLowerCase() ?? '';
    if (normalized.contains('ansiedad') ||
        normalized.contains('ansioso') ||
        normalized.contains('preocup') ||
        normalized.contains('miedo')) {
      return byId('paz_para_la_ansiedad');
    }
    if (normalized.contains('gratitud') ||
        normalized.contains('agradecid') ||
        normalized.contains('alegr') ||
        normalized.contains('feliz')) {
      return byId('gratitud_cotidiana');
    }
    return byId('volver_a_confiar');
  }
}
