import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/prayers/domain/prayer_catalog.dart';
import 'package:verbum/features/prayers/presentation/prayer_entry_icons.dart';
import 'package:verbum/features/prayers/presentation/prayer_routes.dart';
import 'package:verbum/screens/emotion_passage_read_screen.dart';
import 'package:verbum/screens/intention_prayer_read_screen.dart';
import 'package:verbum/screens/novena_screen.dart';
import 'package:verbum/screens/rosary_guide_screen.dart';
import 'package:verbum/screens/traditional_prayer_screen.dart';
import 'package:verbum/screens/traditional_prayers_list_screen.dart';

void main() {
  final allEntries = {
    for (final t in FaithTradition.values)
      for (final s in prayerSectionsFor(t)) ...s.entries,
  };

  test('cada entrada tiene un icono propio (no el genérico)', () {
    final generic = [
      for (final e in allEntries)
        if (iconForPrayerEntry(e) == VerbumIcons.handsPraying &&
            e.key != 'padre_nuestro')
          e.key,
    ];
    expect(generic, isEmpty);
  });

  test('cada destino abre la pantalla correspondiente con su clave', () {
    for (final e in allEntries) {
      final screen = screenForPrayerEntry(e);
      switch (e.destination) {
        case PrayerDestination.emotionPassage:
          expect((screen as EmotionPassageReadScreen).emotionKey, e.key);
        case PrayerDestination.intentionPrayer:
          expect((screen as IntentionPrayerReadScreen).categoryKey, e.key);
        case PrayerDestination.traditionalPrayer:
          expect((screen as TraditionalPrayerScreen).prayerId, e.key);
        case PrayerDestination.traditionalList:
          final list = screen as TraditionalPrayersListScreen;
          expect(list.category, e.key);
          expect(list.religion, 'cristiana');
        case PrayerDestination.rosaryGuide:
          expect(screen, isA<RosaryGuideScreen>());
        case PrayerDestination.novena:
          expect(screen, isA<NovenaScreen>());
      }
    }
  });
}
