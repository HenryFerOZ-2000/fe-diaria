import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/photos/verbum_photos.dart';
import 'package:verbum/features/today/presentation/cover_photos.dart';

void main() {
  test('de noche usa la capilla bajo las estrellas', () {
    expect(coverPhotoFor(DateTime(2026, 9, 30, 21)), VerbumPhotos.coverNight);
    expect(coverPhotoFor(DateTime(2026, 9, 30, 3)), VerbumPhotos.coverNight);
  });

  test('de día rota un paisaje distinto cada día', () {
    final week = {
      for (var d = 1; d <= 3; d++) coverPhotoFor(DateTime(2026, 9, d, 9)),
    };
    expect(week, coverDayPhotos.toSet());
    expect(
      coverPhotoFor(DateTime(2026, 9, 30, 8)),
      coverPhotoFor(DateTime(2026, 9, 30, 17)),
      reason: 'el mismo día mantiene la misma foto',
    );
  });
}
