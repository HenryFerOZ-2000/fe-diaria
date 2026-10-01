import '../../../design_system/photos/verbum_photos.dart';
import '../application/today_schedule.dart';

/// Paisajes serenos de la portada de "Hoy": cielo limpio arriba y sombra
/// abajo, donde va el versículo.
const coverDayPhotos = [
  VerbumPhotos.coverMountains,
  VerbumPhotos.coverSky,
  VerbumPhotos.coverForest,
];

/// De día rota un paisaje por día del año; de noche, la capilla bajo las
/// estrellas.
VerbumPhotos coverPhotoFor(DateTime now) {
  if (now.hour >= nightPrayerStartHour || now.hour < 5) {
    return VerbumPhotos.coverNight;
  }
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return coverDayPhotos[dayOfYear % coverDayPhotos.length];
}
