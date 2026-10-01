import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../application/reader_tone.dart';

/// Colores de la página de lectura según el tono elegido.
class ReaderColors {
  const ReaderColors({required this.page, required this.text});

  final Color page;
  final Color text;

  static const _warmPage = Color(0xFFF1E6D2);
  static const _warmText = Color(0xFF332A23);

  factory ReaderColors.of(BuildContext context, ReaderTone tone) {
    final p = context.palette;
    return switch (tone) {
      ReaderTone.system => ReaderColors(page: p.background, text: p.ink),
      ReaderTone.warm => const ReaderColors(page: _warmPage, text: _warmText),
      ReaderTone.night => ReaderColors(
        page: VerbumPalette.dark.background,
        text: VerbumPalette.dark.ink,
      ),
    };
  }

  /// Muestra del tono para el selector de ajustes.
  static Color swatch(BuildContext context, ReaderTone tone) =>
      ReaderColors.of(context, tone).page;
}
