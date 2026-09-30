import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';

enum VIconButtonVariant {
  /// Círculo con filete fino sobre papel (acciones de cabecera).
  outlined,

  /// Sin borde ni fondo (acciones secundarias dentro de tarjetas).
  ghost,

  /// Relleno en tinta (acción principal, p. ej. reproducir).
  solid,
}

/// Botón circular con icono. Siempre exige [semanticLabel] por accesibilidad.
class VIconButton extends StatelessWidget {
  const VIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = VIconButtonVariant.outlined,
    this.weight = VIconWeight.regular,
    this.size = 40,
    this.showBadge = false,
    this.color,
  });

  final VerbumIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final VIconButtonVariant variant;
  final VIconWeight weight;
  final double size;
  final bool showBadge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      VIconButtonVariant.outlined => (
        p.surface,
        p.ink,
        BorderSide(color: p.line),
      ),
      VIconButtonVariant.ghost => (Colors.transparent, p.ink, BorderSide.none),
      VIconButtonVariant.solid => (p.ink, p.onInk, BorderSide.none),
    };

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: Material(
          color: bg,
          shape: CircleBorder(side: side),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VIcon(
                    icon,
                    weight: weight,
                    size: size * 0.47,
                    color: color ?? fg,
                  ),
                  if (showBadge)
                    Positioned(
                      top: size * 0.2,
                      right: size * 0.22,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.rubric,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: bg == Colors.transparent ? p.background : bg,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
