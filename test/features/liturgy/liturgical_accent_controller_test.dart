import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/application/liturgical_accent_controller.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';

import 'today_liturgy_section_test.dart' show FakeLiturgyService, catholicDay;

void main() {
  group('resolveLiturgicalAccent', () {
    test('usa el primer color de la celebración para católicos', () {
      expect(
        resolveLiturgicalAccent(
          tradition: FaithTradition.catholic,
          day: catholicDay,
        ),
        LiturgicalColor.green,
      );
    });

    test('no aplica calendario a evangélicos ni cristianos generales', () {
      for (final tradition in [
        FaithTradition.evangelical,
        FaithTradition.general,
        FaithTradition.unset,
      ]) {
        expect(
          resolveLiturgicalAccent(tradition: tradition, day: catholicDay),
          isNull,
          reason: tradition.name,
        );
      }
    });

    test('sin día litúrgico vuelve al acento neutro', () {
      expect(
        resolveLiturgicalAccent(tradition: FaithTradition.catholic, day: null),
        isNull,
      );
    });
  });

  group('LiturgicalAccentController', () {
    test(
      'carga el color del día y se actualiza al cambiar de tradición',
      () async {
        var tradition = FaithTradition.catholic;
        final changes = ValueNotifier(0);
        final service = FakeLiturgyService(day: catholicDay);
        final controller = LiturgicalAccentController(
          readTradition: () => tradition,
          loaderFor: (_) => service,
          traditionChanges: changes,
        );
        addTearDown(controller.dispose);

        await controller.refresh();
        expect(controller.color, LiturgicalColor.green);

        tradition = FaithTradition.evangelical;
        changes.value++;
        await Future<void>.delayed(Duration.zero);
        expect(controller.color, isNull);
        expect(
          service.calls,
          1,
          reason: 'no consulta liturgia para evangélicos',
        );
      },
    );

    test('un error de carga deja el acento neutro sin lanzar', () async {
      final controller = LiturgicalAccentController(
        readTradition: () => FaithTradition.catholic,
        loaderFor: (_) => FakeLiturgyService(error: StateError('sin asset')),
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.color, isNull);
    });
  });
}
