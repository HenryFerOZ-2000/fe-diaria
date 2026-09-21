import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/liturgy/application/liturgy_service.dart';
import 'package:verbum/features/liturgy/data/liturgy_repository.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';

final class FakeLiturgyRepository implements LiturgyRepository {
  DateTime? requestedDate;
  CalendarSelection? requestedSelection;

  @override
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  }) async {
    requestedDate = date;
    requestedSelection = selection;
    return null;
  }
}

void main() {
  test('today usa la fecha local inyectada y la selección Ecuador', () async {
    final repository = FakeLiturgyRepository();
    final service = LiturgyService(
      repository: repository,
      selection: CalendarSelection.country('EC'),
      localNow: () => DateTime(2026, 9, 19, 23, 30),
    );

    await service.today();

    expect(repository.requestedDate, DateTime(2026, 9, 19));
    expect(repository.requestedSelection, CalendarSelection.country('EC'));
  });

  test('calcula el siguiente cambio de día local', () {
    final service = LiturgyService(
      repository: FakeLiturgyRepository(),
      selection: const CalendarSelection.generalRoman(),
      localNow: () => DateTime(2026, 9, 20, 23, 59, 59),
    );

    expect(service.untilNextDay(), const Duration(seconds: 2));
  });
}
