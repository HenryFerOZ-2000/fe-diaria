import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/today/application/constancy_progress.dart';

void main() {
  ConstancyProgress p(int days, {int done = 0, int total = 3}) =>
      ConstancyProgress.from(
        totalDays: days,
        completedMoments: done,
        totalMoments: total,
      );

  test('avanza entre hitos', () {
    expect(p(0).nextMilestone, 3);
    expect(p(0).progress, 0);
    expect(p(5).nextMilestone, 7);
    expect(p(5).progress, closeTo(0.5, 0.001)); // de 3 a 7
    expect(p(400).nextMilestone, 730);
  });

  test('mensajes del día', () {
    expect(p(0).todayMessage, 'Comienza hoy tu recorrido');
    expect(p(4, done: 2).todayMessage, '1 momento pendiente para hoy');
    expect(p(4, done: 1).todayMessage, '2 momentos pendientes para hoy');
    expect(p(4, done: 3).todayMessage, 'Tu constancia está a salvo hoy');
  });

  test('etiqueta de días en singular y plural', () {
    expect(p(1).daysLabel, '1 día');
    expect(p(12).daysLabel, '12 días');
  });
}
