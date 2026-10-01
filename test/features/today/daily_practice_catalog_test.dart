import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/today/domain/daily_practice_catalog.dart';

void main() {
  test(
    'la práctica del día es estable en la fecha y rota al día siguiente',
    () {
      final today = dailyPracticeFor(DateTime(2026, 9, 30, 8));
      expect(dailyPracticeFor(DateTime(2026, 9, 30, 22)).title, today.title);
      expect(dailyPracticeFor(DateTime(2026, 10, 1)).title, isNot(today.title));
      expect(today.id, 'practice');
      expect(today.content, isNotEmpty);
    },
  );
}
