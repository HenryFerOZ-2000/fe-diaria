import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Fondo de Verbum: blanco que se funde en lavanda.
///
/// [glowAlignment] se conserva por compatibilidad; ya no hay resplandor.
class VerbumAmbientBackground extends StatelessWidget {
  final Widget child;
  final Alignment glowAlignment;
  final Gradient? gradient;
  final Color? color;

  const VerbumAmbientBackground({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(1.15, -1.1),
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Lavanda que se hace más profunda hacia abajo (de noche, índigo profundo uniforme).
    final fallback = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? [p.background, p.background]
          // Empieza en el mismo lavanda del Scaffold: sin corte bajo la barra.
          : [p.background, p.background, p.surfaceMuted],
      stops: dark ? null : const [0, .55, 1],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? (gradient ?? fallback) : null,
      ),
      child: child,
    );
  }
}
