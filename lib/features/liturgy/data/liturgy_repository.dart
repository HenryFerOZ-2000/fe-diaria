import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';

abstract interface class LiturgyRepository {
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  });
}
