import 'package:flutter/material.dart';

import 'verbum_palette.dart';

/// Sombras suaves teñidas de índigo: las superficies flotan sin filetes.
abstract final class VerbumShadows {
  /// Tarjetas y grupos.
  static List<BoxShadow> soft(VerbumPalette p) => [
    BoxShadow(
      color: p.ink.withValues(
        alpha: p.background.computeLuminance() > .5 ? .08 : .3,
      ),
      blurRadius: 28,
      spreadRadius: -6,
      offset: const Offset(0, 12),
    ),
  ];

  /// Elementos pequeños (chips, tiles compactos).
  static List<BoxShadow> subtle(VerbumPalette p) => [
    BoxShadow(
      color: p.ink.withValues(
        alpha: p.background.computeLuminance() > .5 ? .06 : .25,
      ),
      blurRadius: 14,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];
}
