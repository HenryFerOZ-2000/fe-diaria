import '../../../faith/faith_tradition.dart';
import '../../../faith/tradition_capabilities.dart';

/// A qué tipo de pantalla lleva una entrada del catálogo.
enum PrayerDestination {
  /// Pasaje bíblico según una emoción (`EmotionPassageReadScreen`).
  emotionPassage,

  /// Oración por una intención (`IntentionPrayerReadScreen`).
  intentionPrayer,

  /// Una oración tradicional concreta (`TraditionalPrayerScreen`).
  traditionalPrayer,

  /// Lista de oraciones de una categoría (`TraditionalPrayersListScreen`).
  traditionalList,

  /// Guía del Santo Rosario (`RosaryGuideScreen`).
  rosaryGuide,

  /// Novena de Navidad (`NovenaScreen`).
  novena,
}

final class PrayerEntry {
  const PrayerEntry({
    required this.key,
    required this.title,
    required this.destination,
    this.subtitle,
  });

  /// Clave del contenido: emoción, categoría, id de oración o categoría de
  /// lista, según [destination].
  final String key;
  final String title;
  final String? subtitle;
  final PrayerDestination destination;
}

final class PrayerSection {
  const PrayerSection({
    required this.id,
    required this.title,
    required this.entries,
  });

  final String id;
  final String title;
  final List<PrayerEntry> entries;
}

const _emotions = PrayerSection(
  id: 'emotion',
  title: 'Según cómo me siento',
  entries: [
    PrayerEntry(
      key: 'ansiedad',
      title: 'Ansiedad',
      subtitle: 'Paz en la inquietud',
      destination: PrayerDestination.emotionPassage,
    ),
    PrayerEntry(
      key: 'tristeza',
      title: 'Tristeza',
      subtitle: 'Consuelo y esperanza',
      destination: PrayerDestination.emotionPassage,
    ),
    PrayerEntry(
      key: 'paz_interior',
      title: 'Paz interior',
      subtitle: 'Serenidad del alma',
      destination: PrayerDestination.emotionPassage,
    ),
    PrayerEntry(
      key: 'gratitud',
      title: 'Gratitud',
      subtitle: 'Dar gracias por todo',
      destination: PrayerDestination.emotionPassage,
    ),
    PrayerEntry(
      key: 'perdon',
      title: 'Perdón',
      subtitle: 'Sanar y reconciliar',
      destination: PrayerDestination.emotionPassage,
    ),
    PrayerEntry(
      key: 'fortaleza',
      title: 'Fortaleza',
      subtitle: 'Ánimo en la prueba',
      destination: PrayerDestination.emotionPassage,
    ),
  ],
);

const _intentions = PrayerSection(
  id: 'intention',
  title: 'Por intención',
  entries: [
    PrayerEntry(
      key: 'salud',
      title: 'Salud',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'familia',
      title: 'Familia',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'trabajo',
      title: 'Trabajo',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'proteccion',
      title: 'Protección',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'pareja',
      title: 'Pareja',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'hijos',
      title: 'Hijos',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'sabiduria',
      title: 'Sabiduría',
      destination: PrayerDestination.intentionPrayer,
    ),
    PrayerEntry(
      key: 'prosperidad',
      title: 'Prosperidad',
      destination: PrayerDestination.intentionPrayer,
    ),
  ],
);

const _catholicPrayers = [
  PrayerEntry(
    key: 'padre_nuestro',
    title: 'Padre Nuestro',
    destination: PrayerDestination.traditionalPrayer,
  ),
  PrayerEntry(
    key: 'ave_maria',
    title: 'Ave María',
    destination: PrayerDestination.traditionalPrayer,
  ),
  PrayerEntry(
    key: 'credo',
    title: 'Credo',
    destination: PrayerDestination.traditionalPrayer,
  ),
  PrayerEntry(
    key: 'espiritu_santo',
    title: 'Espíritu Santo',
    destination: PrayerDestination.traditionalPrayer,
  ),
  PrayerEntry(
    key: 'sanacion',
    title: 'Sanación',
    destination: PrayerDestination.traditionalPrayer,
  ),
  PrayerEntry(
    key: 'consagracion',
    title: 'Consagración',
    destination: PrayerDestination.traditionalPrayer,
  ),
];

const _christianLists = [
  PrayerEntry(
    key: 'biblicas',
    title: 'Oraciones bíblicas',
    destination: PrayerDestination.traditionalList,
  ),
  PrayerEntry(
    key: 'promesas',
    title: 'Promesas bíblicas',
    destination: PrayerDestination.traditionalList,
  ),
  PrayerEntry(
    key: 'otras',
    title: 'Otras oraciones cristianas',
    destination: PrayerDestination.traditionalList,
  ),
];

/// Tradiciones que ven oraciones bíblicas en lugar de las tradicionales
/// católicas.
bool usesBiblicalPrayers(FaithTradition tradition) =>
    tradition == FaithTradition.evangelical ||
    tradition == FaithTradition.general;

const _rosary = PrayerEntry(
  key: 'rosario',
  title: 'Santo Rosario',
  subtitle: 'Misterios de hoy',
  destination: PrayerDestination.rosaryGuide,
);

const _novena = PrayerEntry(
  key: 'novena_navidad',
  title: 'Novena de Navidad',
  subtitle: 'Nueve días',
  destination: PrayerDestination.novena,
);

/// Secciones de la pantalla de Oraciones para una tradición.
List<PrayerSection> prayerSectionsFor(FaithTradition tradition) {
  final caps = TraditionCapabilities.forTradition(tradition);
  return [
    _emotions,
    _intentions,
    PrayerSection(
      id: 'traditional',
      title: TraditionUiStrings.prayersTraditionalSectionTitle(tradition),
      entries: usesBiblicalPrayers(tradition)
          ? _christianLists
          : [
              if (caps.showRosaryGuide) _rosary,
              if (caps.showNovena) _novena,
              ..._catholicPrayers,
            ],
    ),
  ];
}

/// Oraciones para "Orar ahora" en Hoy: las tradicionales, empezando por
/// una distinta según el momento del día (madrugada, mañana, tarde,
/// noche), para que la portada no muestre siempre lo mismo.
List<PrayerEntry> prayNowEntries(FaithTradition tradition, int hour) {
  final entries = prayerSectionsFor(
    tradition,
  ).firstWhere((s) => s.id == 'traditional').entries;
  if (entries.isEmpty) return entries;
  final start = (hour ~/ 6) % entries.length;
  return [...entries.skip(start), ...entries.take(start)];
}
