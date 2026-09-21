import '../../../faith/faith_tradition.dart';
import 'calendar_selection.dart';

enum PreferenceOrigin { deviceDefault, userSelected }

final class CalendarProfile {
  const CalendarProfile({
    required this.languageCode,
    required this.tradition,
    required this.deviceCountryCode,
    required this.selection,
    required this.selectionOrigin,
    required this.utcOffset,
  });

  final String languageCode;
  final FaithTradition tradition;
  final String? deviceCountryCode;
  final CalendarSelection selection;
  final PreferenceOrigin selectionOrigin;
  final Duration utcOffset;
}
