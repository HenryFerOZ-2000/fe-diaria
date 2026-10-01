import '../../../design_system/photos/verbum_photos.dart';

/// Foto de cada camino espiritual.
VerbumPhotos photoForPath(String id) => switch (id) {
  'volver_a_confiar' => VerbumPhotos.pathFlowers,
  'paz_para_la_ansiedad' => VerbumPhotos.lake,
  'gratitud_cotidiana' => VerbumPhotos.morning,
  'dormir_en_paz' => VerbumPhotos.night,
  _ => VerbumPhotos.clouds,
};
