import 'package:flutter/material.dart';

import 'verbum_palette.dart';

/// Sombras suaves teñidas de tinta: de día las superficies flotan sin
/// filetes. De noche no hay sombras (una sombra clara brillaría sobre el
/// fondo oscuro); las superficies se separan con un filete fino.
abstract final class VerbumShadows {
  static const _tinta = Color(0xFF22245A);

  static bool _light(VerbumPalette p) => p.background.computeLuminance() > .5;

  /// Color para `shadowColor` de Material: tinta de día, ninguno de noche.
  static Color tint(VerbumPalette p, [double alpha = .18]) =>
      _light(p) ? _tinta.withValues(alpha: alpha) : Colors.transparent;

  /// Tarjetas y grupos.
  static List<BoxShadow> soft(VerbumPalette p) => _light(p)
      ? [
          BoxShadow(
            color: _tinta.withValues(alpha: .08),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ]
      : const [];

  /// Elementos pequeños (chips, tiles compactos).
  static List<BoxShadow> subtle(VerbumPalette p) => _light(p)
      ? [
          BoxShadow(
            color: _tinta.withValues(alpha: .06),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ]
      : const [];
}
