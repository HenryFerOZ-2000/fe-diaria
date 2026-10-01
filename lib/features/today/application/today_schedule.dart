/// Momento del día según las horas litúrgicas (Laudes, mediodía, Completas).
enum DayHour { morning, midday, night }

DayHour dayHourFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return DayHour.morning;
  if (hour >= 12 && hour < 19) return DayHour.midday;
  return DayHour.night;
}

/// Hora a partir de la cual se abre la oración de la noche.
const nightPrayerStartHour = 19;

bool isNightPrayerAvailable(DateTime now) => now.hour >= nightPrayerStartHour;

/// "Buenos días", "Buenas tardes" o "Buenas noches", con nombre si lo hay.
String greetingFor(DateTime now, {String? name}) {
  final base = switch (dayHourFor(now)) {
    DayHour.morning => 'Buenos días',
    DayHour.midday => 'Buenas tardes',
    DayHour.night => 'Buenas noches',
  };
  final first = firstName(name);
  return first == null ? base : '$base, $first';
}

/// Primer nombre visible, o `null` si no hay un nombre utilizable.
String? firstName(String? fullName) {
  final trimmed = fullName?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Invitación breve para el encabezado según el momento del día.
String dayInvitationFor(DateTime now) => switch (dayHourFor(now)) {
  DayHour.morning => 'Comienza el día en su presencia',
  DayHour.midday => 'Haz una pausa para el alma',
  DayHour.night => 'Termina el día en paz',
};

const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Fecha corta en español sin depender de datos de locale: "Mié 30 sep".
String shortSpanishDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

const _longWeekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Fecha con el día completo: "Miércoles 30 sep".
String longSpanishDate(DateTime date) =>
    '${_longWeekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
