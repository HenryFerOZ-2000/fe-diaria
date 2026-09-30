import '../../../design_system/icons/verbum_icons.dart';
import '../application/today_schedule.dart';

VerbumIcons iconForDayHour(DayHour hour) => switch (hour) {
  DayHour.morning => VerbumIcons.sunHorizon,
  DayHour.midday => VerbumIcons.sun,
  DayHour.night => VerbumIcons.moonStars,
};
