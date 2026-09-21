import '../data/liturgy_repository.dart';
import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';

abstract interface class DailyLiturgyLoader {
  Future<LiturgicalDay?> today();
  Duration untilNextDay();
}

final class LiturgyService implements DailyLiturgyLoader {
  LiturgyService({
    required this.repository,
    required this.selection,
    DateTime Function()? localNow,
  }) : _localNow = localNow ?? DateTime.now;

  final LiturgyRepository repository;
  final CalendarSelection selection;
  final DateTime Function() _localNow;

  @override
  Future<LiturgicalDay?> today() => forDate(_localNow().toLocal());

  @override
  Duration untilNextDay() {
    final now = _localNow().toLocal();
    return DateTime(now.year, now.month, now.day + 1).difference(now) +
        const Duration(seconds: 1);
  }

  Future<LiturgicalDay?> forDate(DateTime value) {
    return repository.forDate(
      DateTime(value.year, value.month, value.day),
      selection: selection,
    );
  }
}
