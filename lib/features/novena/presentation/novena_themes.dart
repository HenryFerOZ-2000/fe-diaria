import '../../../design_system/icons/verbum_icons.dart';
import '../../../design_system/photos/verbum_photos.dart';

/// Temática de cada día de la Novena de Navidad, tomada de su reflexión.
typedef NovenaTheme = ({
  String name,
  String line,
  VerbumIcons icon,
  VerbumPhotos photo,
});

const _themes = <NovenaTheme>[
  (
    name: 'La espera',
    line: 'Preparamos el corazón como María y José.',
    icon: VerbumIcons.hourglass,
    photo: VerbumPhotos.candle,
  ),
  (
    name: 'La esperanza',
    line: 'Como los pastores, esperamos la luz.',
    icon: VerbumIcons.sunHorizon,
    photo: VerbumPhotos.morning,
  ),
  (
    name: 'La paz',
    line: 'Jesús trae la paz verdadera.',
    icon: VerbumIcons.bird,
    photo: VerbumPhotos.lake,
  ),
  (
    name: 'La alegría',
    line: 'Una buena noticia que llena de gozo.',
    icon: VerbumIcons.sparkle,
    photo: VerbumPhotos.sunset,
  ),
  (
    name: 'La humildad',
    line: 'Dios nace pequeño en un pesebre.',
    icon: VerbumIcons.leaf,
    photo: VerbumPhotos.handsTogether,
  ),
  (
    name: 'El amor',
    line: 'Tanto nos amó que nos dio a su Hijo.',
    icon: VerbumIcons.heart,
    photo: VerbumPhotos.prayingHands,
  ),
  (
    name: 'La fe',
    line: 'María creyó en la promesa.',
    icon: VerbumIcons.flame,
    photo: VerbumPhotos.stainedGlass,
  ),
  (
    name: 'La perseverancia',
    line: 'La esperanza nos sostiene hasta el final.',
    icon: VerbumIcons.path,
    photo: VerbumPhotos.pathFlowers,
  ),
  (
    name: 'La llegada',
    line: 'La estrella anuncia que Jesús está cerca.',
    icon: VerbumIcons.starFour,
    photo: VerbumPhotos.night,
  ),
];

/// Temática del [day] (1–9); fuera de rango usa el día más cercano.
NovenaTheme novenaThemeFor(int day) => _themes[(day - 1).clamp(0, 8)];
