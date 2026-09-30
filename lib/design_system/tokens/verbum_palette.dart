import 'package:flutter/material.dart';

/// Paleta "Vitela y tinta": papel de libro litúrgico, tinta, rúbrica roja y
/// pan de oro. El [accent] es el único color dinámico: lo decide el tiempo
/// litúrgico (ver `LiturgicalAccentController`).
@immutable
class VerbumPalette extends ThemeExtension<VerbumPalette> {
  const VerbumPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.rubric,
    required this.gold,
    required this.goldSoft,
    required this.line,
    required this.lineSoft,
    required this.accent,
    required this.accentSoft,
    required this.onInk,
    required this.emphasis,
    required this.onEmphasis,
    required this.inverse,
    required this.onInverse,
  });

  /// Fondo de página (vitela).
  final Color background;

  /// Tarjetas y superficies elevadas (papel).
  final Color surface;

  /// Superficies secundarias, bloques de apoyo.
  final Color surfaceMuted;

  /// Texto principal y botones sólidos.
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;

  /// Rojo de las rúbricas: etiquetas, capitulares, estado activo.
  final Color rubric;

  /// Pan de oro: citas, ornamentos, iconos decorativos.
  final Color gold;
  final Color goldSoft;

  /// Filetes y bordes finos.
  final Color line;
  final Color lineSoft;

  /// Color del tiempo litúrgico.
  final Color accent;
  final Color accentSoft;

  /// Texto sobre [ink].
  final Color onInk;

  /// Controles de énfasis pequeños (botón principal, paso hecho, día
  /// cumplido). Tinta de día, luz de vela de noche.
  final Color emphasis;
  final Color onEmphasis;

  /// Superficies grandes invertidas (tarjeta destacada, barra de acciones).
  /// Tinta de día; de noche una superficie elevada para no deslumbrar.
  final Color inverse;
  final Color onInverse;

  static const light = VerbumPalette(
    background: Color(0xFFF5EEE1),
    surface: Color(0xFFFBF7EF),
    surfaceMuted: Color(0xFFEDE3D1),
    ink: Color(0xFF1E1915),
    inkMuted: Color(0xFF5B5047),
    inkSubtle: Color(0xFF8D8176),
    rubric: Color(0xFF9C2A22),
    gold: Color(0xFFB0823A),
    goldSoft: Color(0xFFE8D5AE),
    line: Color(0xFFDCCFB9),
    lineSoft: Color(0xFFE8DDCB),
    accent: Color(0xFFB0823A),
    accentSoft: Color(0xFFF1E6CF),
    onInk: Color(0xFFF5EEE1),
    emphasis: Color(0xFF1E1915),
    onEmphasis: Color(0xFFF5EEE1),
    inverse: Color(0xFF1E1915),
    onInverse: Color(0xFFF5EEE1),
  );

  /// Modo noche ("Completas"): azul noche y luz de vela.
  static const dark = VerbumPalette(
    background: Color(0xFF101219),
    surface: Color(0xFF191C26),
    surfaceMuted: Color(0xFF232734),
    ink: Color(0xFFEDE6D8),
    inkMuted: Color(0xFFA39C8E),
    inkSubtle: Color(0xFF6F6A62),
    rubric: Color(0xFFE08A7F),
    gold: Color(0xFFE3B866),
    goldSoft: Color(0xFF4A3D24),
    line: Color(0xFF2B2F3C),
    lineSoft: Color(0xFF232734),
    accent: Color(0xFFE3B866),
    accentSoft: Color(0xFF2E2A22),
    onInk: Color(0xFF101219),
    emphasis: Color(0xFFE3B866),
    onEmphasis: Color(0xFF101219),
    inverse: Color(0xFF252A38),
    onInverse: Color(0xFFEDE6D8),
  );

  static VerbumPalette of(BuildContext context) =>
      Theme.of(context).extension<VerbumPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Devuelve la paleta con el acento litúrgico aplicado.
  VerbumPalette withAccent(Color? value) {
    if (value == null) return this;
    return copyWith(
      accent: value,
      accentSoft: Color.alphaBlend(
        value.withValues(
          alpha: background.computeLuminance() > 0.5 ? 0.14 : 0.18,
        ),
        background,
      ),
    );
  }

  @override
  VerbumPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? rubric,
    Color? gold,
    Color? goldSoft,
    Color? line,
    Color? lineSoft,
    Color? accent,
    Color? accentSoft,
    Color? onInk,
    Color? emphasis,
    Color? onEmphasis,
    Color? inverse,
    Color? onInverse,
  }) {
    return VerbumPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      rubric: rubric ?? this.rubric,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onInk: onInk ?? this.onInk,
      emphasis: emphasis ?? this.emphasis,
      onEmphasis: onEmphasis ?? this.onEmphasis,
      inverse: inverse ?? this.inverse,
      onInverse: onInverse ?? this.onInverse,
    );
  }

  @override
  VerbumPalette lerp(ThemeExtension<VerbumPalette>? other, double t) {
    if (other is! VerbumPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VerbumPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkSubtle: l(inkSubtle, other.inkSubtle),
      rubric: l(rubric, other.rubric),
      gold: l(gold, other.gold),
      goldSoft: l(goldSoft, other.goldSoft),
      line: l(line, other.line),
      lineSoft: l(lineSoft, other.lineSoft),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onInk: l(onInk, other.onInk),
      emphasis: l(emphasis, other.emphasis),
      onEmphasis: l(onEmphasis, other.onEmphasis),
      inverse: l(inverse, other.inverse),
      onInverse: l(onInverse, other.onInverse),
    );
  }
}
