import '../../../design_system/icons/verbum_icons.dart';
import '../../../design_system/photos/verbum_photos.dart';
import '../domain/prayer_catalog.dart';

VerbumIcons iconForPrayerEntry(PrayerEntry entry) => switch (entry.key) {
  'ansiedad' => VerbumIcons.wind,
  'tristeza' => VerbumIcons.cloudRain,
  'paz_interior' => VerbumIcons.flowerLotus,
  'gratitud' => VerbumIcons.sun,
  'perdon' => VerbumIcons.handshake,
  'fortaleza' => VerbumIcons.mountains,
  'salud' => VerbumIcons.firstAid,
  'familia' => VerbumIcons.houseLine,
  'trabajo' => VerbumIcons.briefcase,
  'proteccion' => VerbumIcons.shield,
  'pareja' => VerbumIcons.heart,
  'hijos' => VerbumIcons.baby,
  'sabiduria' => VerbumIcons.graduationCap,
  'prosperidad' => VerbumIcons.handCoins,
  'rosario' => VerbumIcons.starFour,
  'novena_navidad' => VerbumIcons.calendarCheck,
  'padre_nuestro' => VerbumIcons.handsPraying,
  'ave_maria' => VerbumIcons.flowerLotus,
  'credo' => VerbumIcons.cross,
  'espiritu_santo' => VerbumIcons.bird,
  'sanacion' => VerbumIcons.heartbeat,
  'consagracion' => VerbumIcons.crown,
  'biblicas' => VerbumIcons.bookOpenText,
  'promesas' => VerbumIcons.scroll,
  'otras' => VerbumIcons.handHeart,
  _ => VerbumIcons.handsPraying,
};

/// Foto de las oraciones que se muestran como tarjeta con imagen.
VerbumPhotos photoForPrayerEntry(PrayerEntry entry) => switch (entry.key) {
  'rosario' => VerbumPhotos.rosary,
  'novena_navidad' => VerbumPhotos.candle,
  'padre_nuestro' => VerbumPhotos.sunrisePrayer,
  'ave_maria' => VerbumPhotos.marianWindow,
  'credo' => VerbumPhotos.stainedGlass,
  'espiritu_santo' => VerbumPhotos.clouds,
  'sanacion' => VerbumPhotos.handsTogether,
  'consagracion' => VerbumPhotos.prayingHands,
  'biblicas' => VerbumPhotos.coffeeBible,
  'promesas' => VerbumPhotos.sunset,
  'otras' => VerbumPhotos.journaling,
  _ => VerbumPhotos.windowReading,
};
