import 'package:flutter/material.dart';

/// Paleta "Camino claro": blanco que se funde en lavanda, índigo y
/// periwinkle, con amarillo mantequilla como único acento cálido.
///
/// Los nombres de algunos tokens vienen de la primera dirección ("libro de
/// horas") y se conservan para no tocar cada pantalla: [rubric] es el color
/// de énfasis textual (índigo) y [gold] el color decorativo (periwinkle).
/// Todos los colores salen de la paleta de la propuesta: blanco, lavanda,
/// lavanda 2, periwinkle, índigo, tinta, mantequilla y salvia.
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
    required this.sage,
    required this.sageSoft,
    required this.sageInk,
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

  /// Acento periwinkle y su fondo lavanda.
  final Color accent;
  final Color accentSoft;

  /// Texto sobre [ink].
  final Color onInk;

  /// Controles de énfasis pequeños (botón principal, paso hecho, día
  /// cumplido). Tinta de día, luz de vela de noche.
  final Color emphasis;
  final Color onEmphasis;

  /// Superficies grandes invertidas (Hoy, tarjeta destacada, barra de
  /// acciones). Periwinkle de día; de noche una superficie elevada.
  final Color inverse;
  final Color onInverse;

  /// Acento cálido para la acción principal y la constancia.
  final Color butter;
  final Color onButter;

  /// Salvia: lo completado ("Hecho", días cumplidos, pasos terminados).
  /// [sageSoft] es su fondo y [sageInk] el texto sobre ese fondo.
  final Color sage;
  final Color sageSoft;
  final Color sageInk;

  static const light = VerbumPalette(
    background: Color(0xFFF1F2FC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE5E7F8),
    ink: Color(0xFF22245A),
    inkMuted: Color(0xFF5F6290),
    inkSubtle: Color(0xFF9497C2),
    rubric: Color(0xFF4A4EBB),
    gold: Color(0xFF6F72D3),
    goldSoft: Color(0xFFFBF2C6),
    line: Color(0xFFE3E4F3),
    lineSoft: Color(0xFFEEEFF8),
    accent: Color(0xFF6F72D3),
    accentSoft: Color(0xFFE5E7F8),
    onInk: Color(0xFFFFFFFF),
    emphasis: Color(0xFF3A3C8E),
    onEmphasis: Color(0xFFFFFFFF),
    inverse: Color(0xFF6F72D3),
    onInverse: Color(0xFFFFFFFF),
    butter: Color(0xFFF4DF7A),
    onButter: Color(0xFF3A2F05),
    sage: Color(0xFF5FA58A),
    sageSoft: Color(0xFFE1F1EA),
    sageInk: Color(0xFF2E6B55),
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
    sage: Color(0xFF7CC0A4),
    sageSoft: Color(0xFF1C3A31),
    sageInk: Color(0xFF9FD8C0),
  );

  static VerbumPalette of(BuildContext context) =>
      Theme.of(context).extension<VerbumPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

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
    Color? sage,
    Color? sageSoft,
    Color? sageInk,
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
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      sageInk: sageInk ?? this.sageInk,
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
      sage: l(sage, other.sage),
      sageSoft: l(sageSoft, other.sageSoft),
      sageInk: l(sageInk, other.sageInk),
    );
  }
}
