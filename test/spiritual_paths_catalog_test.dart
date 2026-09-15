import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/data/spiritual_paths_catalog.dart';

void main() {
  group('SpiritualPathsCatalog', () {
    test('cada camino ofrece siete días completos y consecutivos', () {
      expect(SpiritualPathsCatalog.paths, isNotEmpty);

      for (final path in SpiritualPathsCatalog.paths) {
        expect(path.days, hasLength(7));
        expect(
          path.days.map((day) => day.number),
          orderedEquals(const [1, 2, 3, 4, 5, 6, 7]),
        );
        for (final day in path.days) {
          expect(day.scripture.trim(), isNotEmpty);
          expect(day.reflection.trim(), isNotEmpty);
          expect(day.prayer.trim(), isNotEmpty);
          expect(day.practice.trim(), isNotEmpty);
        }
      }
    });

    test('la recomendación nocturna prioriza descanso', () {
      expect(SpiritualPathsCatalog.recommend(hour: 22).id, 'dormir_en_paz');
    });

    test('las emociones configurables producen recomendaciones útiles', () {
      expect(
        SpiritualPathsCatalog.recommend(hour: 10, emotion: 'ansioso').id,
        'paz_para_la_ansiedad',
      );
      expect(
        SpiritualPathsCatalog.recommend(hour: 10, emotion: 'preocupado').id,
        'paz_para_la_ansiedad',
      );
      expect(
        SpiritualPathsCatalog.recommend(hour: 10, emotion: 'agradecido').id,
        'gratitud_cotidiana',
      );
      expect(
        SpiritualPathsCatalog.recommend(hour: 10, emotion: 'feliz').id,
        'gratitud_cotidiana',
      );
    });

    test('un id desconocido tiene una alternativa segura', () {
      expect(
        SpiritualPathsCatalog.byId('no_existe'),
        SpiritualPathsCatalog.paths.first,
      );
    });
  });
}
