import 'package:flutter/material.dart';

/// Fondo ambiental de Verbum: luz, profundidad y geometría contemplativa.
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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [
                      Color(0xFF15121D),
                      Color(0xFF211B2C),
                      Color(0xFF17141F),
                    ]
                  : const [
                      Color(0xFFFBF8F1),
                      Color(0xFFF3EEE5),
                      Color(0xFFF8F5EF),
                    ],
            ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: glowAlignment,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.secondary.withValues(alpha: dark ? .16 : .19),
                    scheme.secondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1.35, .55),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.tertiary.withValues(alpha: dark ? .10 : .13),
                    scheme.tertiary.withValues(alpha: 0),
                  ],
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
