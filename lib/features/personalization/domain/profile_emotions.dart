import '../../../design_system/icons/verbum_icons.dart';

/// Estado de ánimo que la persona guarda en su perfil para personalizar
/// versículos y oraciones.
final class ProfileEmotion {
  const ProfileEmotion(this.id, this.label, this.icon);

  /// Valor persistido (ver `PersonalizationService`).
  final String id;
  final String label;
  final VerbumIcons icon;
}

const profileEmotions = [
  ProfileEmotion('ansioso', 'Ansioso', VerbumIcons.wind),
  ProfileEmotion('triste', 'Triste', VerbumIcons.cloudRain),
  ProfileEmotion('agradecido', 'Agradecido', VerbumIcons.handHeart),
  ProfileEmotion('motivado', 'Motivado', VerbumIcons.lightning),
  ProfileEmotion('preocupado', 'Preocupado', VerbumIcons.warningCircle),
  ProfileEmotion('feliz', 'Feliz', VerbumIcons.smiley),
  ProfileEmotion('desanimado', 'Desanimado', VerbumIcons.smileyMeh),
  ProfileEmotion('enojado', 'Enojado', VerbumIcons.flame),
  ProfileEmotion('tranquilo', 'Tranquilo', VerbumIcons.flowerLotus),
];

/// Nombre visible de una emoción guardada; devuelve el valor tal cual si no
/// está en el catálogo (datos antiguos).
String profileEmotionLabel(String id) =>
    profileEmotions.where((e) => e.id == id).firstOrNull?.label ?? id;
