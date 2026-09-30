import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/today/application/today_schedule.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 9, 30, hour);

  test('las horas del día siguen Laudes, mediodía y Completas', () {
    expect(dayHourFor(at(5)), DayHour.morning);
    expect(dayHourFor(at(11)), DayHour.morning);
    expect(dayHourFor(at(12)), DayHour.midday);
    expect(dayHourFor(at(18)), DayHour.midday);
    expect(dayHourFor(at(19)), DayHour.night);
    expect(dayHourFor(at(2)), DayHour.night);
  });

  test('la oración de la noche abre a las 19:00', () {
    expect(isNightPrayerAvailable(at(18)), isFalse);
    expect(isNightPrayerAvailable(at(19)), isTrue);
    expect(isNightPrayerAvailable(at(23)), isTrue);
  });

  test('el saludo usa solo el primer nombre y lo omite si está vacío', () {
    expect(greetingFor(at(8), name: 'Ana María López'), 'Buenos días, Ana');
    expect(greetingFor(at(15), name: '   '), 'Buenas tardes');
    expect(greetingFor(at(21)), 'Buenas noches');
  });

  test('fecha corta en español', () {
    expect(shortSpanishDate(DateTime(2026, 9, 30)), 'Mié 30 sep');
    expect(shortSpanishDate(DateTime(2026, 1, 4)), 'Dom 4 ene');
  });
}
