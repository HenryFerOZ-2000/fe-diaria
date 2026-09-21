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
