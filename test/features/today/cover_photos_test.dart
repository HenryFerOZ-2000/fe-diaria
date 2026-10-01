import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/today/presentation/cover_photos.dart';

void main() {
  test('la noche empieza con la oración de la noche y acaba al amanecer', () {
    expect(isCoverNight(DateTime(2026, 9, 30, 21)), isTrue);
    expect(isCoverNight(DateTime(2026, 9, 30, 3)), isTrue);
    expect(isCoverNight(DateTime(2026, 9, 30, 9)), isFalse);
    expect(isCoverNight(DateTime(2026, 9, 30, 18)), isFalse);
  });
}
