import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'verbum_palette.dart';

/// Las dos únicas familias de la app.
///
/// * [serif] (Cormorant Garamond): la Palabra, títulos y citas.
/// * [sans] (Figtree): interfaz, botones, metadatos.
///
/// Aceptan los mismos parámetros que `GoogleFonts.*`, así sustituyen
/// cualquier llamada directa.
abstract final class VerbumFonts {
  /// Cormorant trae números de estilo antiguo (el 0 parece una "o"); aquí se
  /// activan los números alineados para cifras, fechas y contadores.
  static TextStyle serif({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.cormorantGaramond(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      shadows: shadows,
      fontFeatures: fontFeatures ?? const [FontFeature.liningFigures()],
    );
  }

  static const sans = GoogleFonts.figtree;
  static const sansTextTheme = GoogleFonts.figtreeTextTheme;
}

/// Estilos semánticos. Las pantallas usan estos nombres, nunca tamaños sueltos.
@immutable
class VerbumTypography extends ThemeExtension<VerbumTypography> {
  const VerbumTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.scripture,
    required this.scriptureLarge,
    required this.citation,
    required this.rubric,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.button,
  });

  /// Títulos de pantalla ("Oraciones", "Capítulo 9").
  final TextStyle display;

  /// Saludo y títulos destacados de tarjeta.
  final TextStyle title;

  /// Encabezados de sección ("Tus horas de hoy").
  final TextStyle heading;

  /// Texto bíblico de lectura continua.
  final TextStyle scripture;

  /// Versículo destacado (Palabra del día).
  final TextStyle scriptureLarge;

  /// Referencias bíblicas ("Lucas 9, 62").
  final TextStyle citation;

  /// Etiquetas en versalitas espaciadas ("PALABRA DEL DÍA").
  final TextStyle rubric;

  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle caption;
  final TextStyle button;

  factory VerbumTypography.fromPalette(VerbumPalette p) {
    return VerbumTypography(
      display: VerbumFonts.serif(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 1.05,
        letterSpacing: -0.3,
        color: p.ink,
      ),
      title: VerbumFonts.serif(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.1,
        color: p.ink,
      ),
      heading: VerbumFonts.serif(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: p.ink,
      ),
      scripture: VerbumFonts.serif(
        fontSize: 19,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: p.ink,
      ),
      scriptureLarge: VerbumFonts.serif(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        color: p.ink,
      ),
      citation: VerbumFonts.serif(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: p.gold,
      ),
      rubric: VerbumFonts.sans(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.1,
        color: p.rubric,
      ),
      body: VerbumFonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: p.inkMuted,
      ),
      bodyStrong: VerbumFonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: p.ink,
      ),
      caption: VerbumFonts.sans(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: p.inkSubtle,
      ),
      button: VerbumFonts.sans(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  static VerbumTypography of(BuildContext context) =>
      Theme.of(context).extension<VerbumTypography>() ??
      VerbumTypography.fromPalette(VerbumPalette.of(context));

  @override
  VerbumTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? scripture,
    TextStyle? scriptureLarge,
    TextStyle? citation,
    TextStyle? rubric,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? caption,
    TextStyle? button,
  }) {
    return VerbumTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      scripture: scripture ?? this.scripture,
      scriptureLarge: scriptureLarge ?? this.scriptureLarge,
      citation: citation ?? this.citation,
      rubric: rubric ?? this.rubric,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  @override
  VerbumTypography lerp(ThemeExtension<VerbumTypography>? other, double t) {
    if (other is! VerbumTypography) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return VerbumTypography(
      display: l(display, other.display),
      title: l(title, other.title),
      heading: l(heading, other.heading),
      scripture: l(scripture, other.scripture),
      scriptureLarge: l(scriptureLarge, other.scriptureLarge),
      citation: l(citation, other.citation),
      rubric: l(rubric, other.rubric),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      caption: l(caption, other.caption),
      button: l(button, other.button),
    );
  }
}
