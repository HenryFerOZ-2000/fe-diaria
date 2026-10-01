/// Utilidades de fechas para la constancia. Las fechas se guardan como
/// claves "aaaa-mm-dd" (ver `SpiritualStats.activeDaysMap`).
library;

const spanishMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String ymdKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Días marcados como activos dentro del mes de [month].
int activeDaysInMonth(Map<String, bool> activeDays, DateTime month) =>
    activeDays.entries.where((entry) {
      if (!entry.value) return false;
      final date = DateTime.tryParse(entry.key);
      return date != null &&
          date.year == month.year &&
          date.month == month.month;
    }).length;

/// "Hoy", "Ayer", "12 de septiembre" o un aviso si aún no hay actividad.
String lastActiveLabel(String? lastYmd, DateTime now) {
  final date = lastYmd == null ? null : DateTime.tryParse(lastYmd);
  if (date == null) return 'Aún no hay un día completado';
  if (ymdKey(date) == ymdKey(now)) return 'Hoy';
  if (ymdKey(date) == ymdKey(now.subtract(const Duration(days: 1)))) {
    return 'Ayer';
  }
  return '${date.day} de ${spanishMonths[date.month - 1]}';
}

/// "Septiembre 2026".
String monthTitle(DateTime month) {
  final name = spanishMonths[month.month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} ${month.year}';
}
