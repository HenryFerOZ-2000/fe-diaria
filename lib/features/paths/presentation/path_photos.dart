import '../../../design_system/photos/verbum_photos.dart';

/// Foto de cada camino espiritual.
VerbumPhotos photoForPath(String id) => switch (id) {
  'volver_a_confiar' => VerbumPhotos.pathFlowers,
  'paz_para_la_ansiedad' => VerbumPhotos.lake,
  'gratitud_cotidiana' => VerbumPhotos.morning,
  'dormir_en_paz' => VerbumPhotos.night,
  _ => VerbumPhotos.clouds,
};

const _dayPhotos = [
  VerbumPhotos.windowReading,
  VerbumPhotos.handsOnBible,
  VerbumPhotos.journaling,
  VerbumPhotos.sunset,
  VerbumPhotos.elderReading,
  VerbumPhotos.lake,
  VerbumPhotos.morning,
];

/// Foto de cada día del sendero (se repite si hay más de siete).
VerbumPhotos photoForPathDay(int number) =>
    _dayPhotos[(number - 1) % _dayPhotos.length];
