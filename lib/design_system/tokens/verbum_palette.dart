import 'package:flutter/material.dart';

/// Paleta "Camino claro": blanco que se funde en lavanda, índigo y
/// periwinkle, con amarillo mantequilla como único acento cálido.
///
/// Los nombres de algunos tokens vienen de la primera dirección ("libro de
/// horas") y se conservan para no tocar cada pantalla: [rubric] es el color
/// de énfasis textual (índigo) y [gold] el color decorativo (periwinkle).
/// El [accent] es el único color dinámico: lo decide el tiempo litúrgico
/// (ver `LiturgicalAccentController`).
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
    required this.butter,
    required this.onButter,
  });

  /// Fondo de página (lavanda muy clara).
  final Color background;

  /// Tarjetas y superficies elevadas (blanco).
  final Color surface;

  /// Superficies secundarias, bloques de apoyo.
  final Color surfaceMuted;

  /// Texto principal y botones sólidos.
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;

  /// Énfasis textual (índigo): etiquetas, capitulares, estado activo.
  final Color rubric;

  /// Decorativo (periwinkle): citas, iconos duotono, progreso.
  /// [goldSoft] es el fondo de resaltado (mantequilla suave).
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

  /// Acento cálido para la acción principal y la constancia.
  final Color butter;
  final Color onButter;

  static const light = VerbumPalette(
    background: Color(0xFFF4F5FC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9EBF8),
    ink: Color(0xFF22245A),
    inkMuted: Color(0xFF5F6290),
    inkSubtle: Color(0xFF9497C2),
    rubric: Color(0xFF4A4EBB),
    gold: Color(0xFF6F72D3),
    goldSoft: Color(0xFFFBF2C6),
    line: Color(0xFFE3E4F3),
    lineSoft: Color(0xFFEEEFF8),
    accent: Color(0xFF6F72D3),
    accentSoft: Color(0xFFE9EBF8),
    onInk: Color(0xFFFFFFFF),
    emphasis: Color(0xFF3A3C8E),
    onEmphasis: Color(0xFFFFFFFF),
    inverse: Color(0xFF5D60C4),
    onInverse: Color(0xFFFFFFFF),
    butter: Color(0xFFF4DF7A),
    onButter: Color(0xFF3A2F05),
  );

  /// Modo noche: índigo profundo con la luz mantequilla como énfasis.
  static const dark = VerbumPalette(
    background: Color(0xFF10122A),
    surface: Color(0xFF1A1D3A),
    surfaceMuted: Color(0xFF24284A),
    ink: Color(0xFFEEF0FB),
    inkMuted: Color(0xFFA9ACD6),
    inkSubtle: Color(0xFF6E72A0),
    rubric: Color(0xFFA9ADF7),
    gold: Color(0xFF959AEE),
    goldSoft: Color(0xFF3B3622),
    line: Color(0xFF2C3058),
    lineSoft: Color(0xFF22264A),
    accent: Color(0xFF959AEE),
    accentSoft: Color(0xFF262B52),
    onInk: Color(0xFF10122A),
    emphasis: Color(0xFFF4DF7A),
    onEmphasis: Color(0xFF22245A),
    inverse: Color(0xFF2A2E5E),
    onInverse: Color(0xFFEEF0FB),
    butter: Color(0xFFF4DF7A),
    onButter: Color(0xFF3A2F05),
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
    Color? butter,
    Color? onButter,
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
      butter: butter ?? this.butter,
      onButter: onButter ?? this.onButter,
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
      butter: l(butter, other.butter),
      onButter: l(onButter, other.onButter),
    );
  }
}
