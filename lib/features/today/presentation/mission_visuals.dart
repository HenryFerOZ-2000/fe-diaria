import '../../../controllers/missions_controller.dart';
import '../../../design_system/icons/verbum_icons.dart';

/// Icono de cada momento del camino diario.
VerbumIcons iconForMission(Mission mission) => switch (mission.id) {
  'verse' => VerbumIcons.bookOpenText,
  'morning' => VerbumIcons.handsPraying,
  'practice' => VerbumIcons.handHeart,
  'night' => VerbumIcons.moonStars,
  _ => VerbumIcons.sparkle,
};

/// Nombre corto para los tiles del recorrido.
String shortLabelForMission(Mission mission) => switch (mission.id) {
  'verse' => 'Palabra',
  'morning' => 'Oración',
  'practice' => 'Práctica',
  'night' => 'Noche',
  _ => mission.title,
};
