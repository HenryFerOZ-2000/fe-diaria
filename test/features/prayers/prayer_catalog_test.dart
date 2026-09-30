import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/prayers/domain/prayer_catalog.dart';

void main() {
  List<String> keys(FaithTradition t, String section) => prayerSectionsFor(
    t,
  ).firstWhere((s) => s.id == section).entries.map((e) => e.key).toList();

  test('católicos ven las oraciones tradicionales', () {
    expect(keys(FaithTradition.catholic, 'traditional'), contains('ave_maria'));
    expect(
      prayerSectionsFor(
        FaithTradition.catholic,
      ).last.entries.map((e) => e.destination),
      everyElement(PrayerDestination.traditionalPrayer),
    );
  });

  test(
    'evangélicos y cristianos generales ven listas bíblicas, sin Ave María',
    () {
      for (final t in [FaithTradition.evangelical, FaithTradition.general]) {
        final traditional = keys(t, 'traditional');
        expect(traditional, ['biblicas', 'promesas', 'otras'], reason: t.name);
        expect(traditional, isNot(contains('ave_maria')));
      }
    },
  );

  test('emociones e intenciones son comunes y sus claves son únicas', () {
    for (final t in FaithTradition.values) {
      final sections = prayerSectionsFor(t);
      expect(sections.map((s) => s.id), [
        'emotion',
        'intention',
        'traditional',
      ]);
      for (final s in sections) {
        final k = s.entries.map((e) => e.key).toList();
        expect(k.toSet().length, k.length, reason: '${t.name}/${s.id}');
      }
    }
  });
}
