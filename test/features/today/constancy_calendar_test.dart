import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/today/application/constancy_calendar.dart';
import 'package:verbum/features/today/application/constancy_progress.dart';

void main() {
  final now = DateTime(2026, 9, 30, 20);

  test('clave de fecha y título del mes', () {
    expect(ymdKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(monthTitle(DateTime(2026, 9)), 'Septiembre 2026');
  });

  test('días activos solo del mes pedido', () {
    final map = {
      '2026-09-01': true,
      '2026-09-29': true,
      '2026-09-30': false,
      '2026-08-31': true,
    };
    expect(activeDaysInMonth(map, DateTime(2026, 9)), 2);
  });

  test('etiqueta de la última actividad', () {
    expect(lastActiveLabel('2026-09-30', now), 'Hoy');
    expect(lastActiveLabel('2026-09-29', now), 'Ayer');
    expect(lastActiveLabel('2026-09-12', now), '12 de septiembre');
    expect(lastActiveLabel(null, now), 'Aún no hay un día completado');
  });

  test('hito anterior y días restantes', () {
    final p = ConstancyProgress.from(
      totalDays: 9,
      completedMoments: 0,
      totalMoments: 3,
    );
    expect(p.previousMilestone, 7);
    expect(p.nextMilestone, 14);
    expect(p.remainingDays, 5);
  });
}
