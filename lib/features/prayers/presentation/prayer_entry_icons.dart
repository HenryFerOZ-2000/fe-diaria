import '../../../design_system/icons/verbum_icons.dart';
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
  'padre_nuestro' => VerbumIcons.handsPraying,
  'ave_maria' => VerbumIcons.starFour,
  'credo' => VerbumIcons.cross,
  'espiritu_santo' => VerbumIcons.bird,
  'sanacion' => VerbumIcons.heartbeat,
  'consagracion' => VerbumIcons.crown,
  'biblicas' => VerbumIcons.bookOpenText,
  'promesas' => VerbumIcons.scroll,
  'otras' => VerbumIcons.handHeart,
  _ => VerbumIcons.handsPraying,
};
