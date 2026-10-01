import '../../../controllers/missions_controller.dart';
import 'today_schedule.dart';

/// Un momento del día en el abanico de "Hoy".
final class DayMoment {
  const DayMoment({required this.mission, required this.time});

  final Mission mission;

  /// Hora sugerida, "7:00".
  final String time;

  bool get done => mission.completed;
}

/// Hora sugerida de cada momento, según las horas de oración.
const _times = {
  'verse': '7:00',
  'morning': '12:00',
  'practice': '15:00',
  'night': '$nightPrayerStartHour:00',
};

/// Momentos del día en orden: los esenciales y, al final, la noche.
List<DayMoment> dayMomentsFor(List<Mission> missions) => [
  for (final mission in missions)
    DayMoment(mission: mission, time: _times[mission.id] ?? ''),
];

/// Tarjeta que se muestra al centro al abrir "Hoy": el primer momento
/// esencial pendiente; si ya están todos, la noche (o el último).
int initialMomentIndex(List<DayMoment> moments) {
  final pending = moments.indexWhere((m) => !m.done && !m.mission.isOptional);
  if (pending != -1) return pending;
  final night = moments.indexWhere((m) => m.mission.isOptional && !m.done);
  if (night != -1) return night;
  return moments.isEmpty ? 0 : moments.length - 1;
}
