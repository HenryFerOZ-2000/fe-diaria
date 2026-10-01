import 'package:flutter/material.dart';

import '../domain/liturgical_day.dart';

final class LiturgicalPalette {
  const LiturgicalPalette._();

  static Color accent(LiturgicalColor color, Brightness brightness) {
    return switch (color) {
      LiturgicalColor.white =>
        brightness == Brightness.dark
            ? const Color(0xFFF2E9D8)
            : const Color(0xFF9B7B43),
      LiturgicalColor.green =>
        brightness == Brightness.dark
            ? const Color(0xFF83B5A0)
            : const Color(0xFF3F6F5D),
      LiturgicalColor.red =>
        brightness == Brightness.dark
            ? const Color(0xFFD98B84)
            : const Color(0xFF994742),
      LiturgicalColor.purple =>
        brightness == Brightness.dark
            ? const Color(0xFFB19AC5)
            : const Color(0xFF6B5181),
      LiturgicalColor.rose =>
        brightness == Brightness.dark
            ? const Color(0xFFE0A4B5)
            : const Color(0xFFA95871),
      LiturgicalColor.gold =>
        brightness == Brightness.dark
            ? const Color(0xFFD7BB72)
            : const Color(0xFF8C6A22),
      LiturgicalColor.black =>
        brightness == Brightness.dark
            ? const Color(0xFFC9C5BE)
            : const Color(0xFF3E3C39),
    };
  }

  /// El color tal cual, para un punto o muestra (no para texto).
  static Color swatch(LiturgicalColor color) => switch (color) {
    LiturgicalColor.white => const Color(0xFFFFFFFF),
    LiturgicalColor.green => const Color(0xFF4E8A6F),
    LiturgicalColor.red => const Color(0xFFB8463F),
    LiturgicalColor.purple => const Color(0xFF7A55A0),
    LiturgicalColor.rose => const Color(0xFFE29BB2),
    LiturgicalColor.gold => const Color(0xFFD9B44A),
    LiturgicalColor.black => const Color(0xFF2E2C2A),
  };

  static String label(LiturgicalColor color) => switch (color) {
    LiturgicalColor.white => 'Blanco',
    LiturgicalColor.green => 'Verde',
    LiturgicalColor.red => 'Rojo',
    LiturgicalColor.purple => 'Morado',
    LiturgicalColor.rose => 'Rosa',
    LiturgicalColor.gold => 'Dorado',
    LiturgicalColor.black => 'Negro',
  };
}
