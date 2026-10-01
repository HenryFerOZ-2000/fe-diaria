import '../../../design_system/photos/verbum_photos.dart';
import '../application/today_schedule.dart';

/// La portada de "Hoy" es siempre la cordillera al amanecer: capas azul e
/// índigo, cielo limpio arriba y sombra abajo para el versículo.
const coverPhoto = VerbumPhotos.coverMountains;

/// De noche la misma foto se cubre con un velo más profundo.
bool isCoverNight(DateTime now) =>
    now.hour >= nightPrayerStartHour || now.hour < 5;
