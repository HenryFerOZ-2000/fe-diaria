import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Fondo de Verbum: papel vitela plano con un resplandor tenue de vela.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.background) : null,
        gradient: gradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Align(
              alignment: glowAlignment,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.gold.withValues(alpha: dark ? .10 : .09),
                      p.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
