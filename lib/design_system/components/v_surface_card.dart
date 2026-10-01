import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import '../tokens/verbum_shadows.dart';

enum VSurfaceTone {
  /// Papel blanco con sombra suave (por defecto).
  paper,

  /// Bloque de apoyo sin borde, un tono más oscuro que el fondo.
  muted,

  /// Invertido en tinta (estado completado / destacado).
  ink,

  /// Tinte del tiempo litúrgico.
  accent,

  /// Mantequilla: lo que toca ahora (capítulo actual, día de hoy).
  butter,
}

/// Superficie base de la app: papel con sombra suave o bloques de color.
///
/// [framed] añade el doble filete interior de los libros litúrgicos; úsalo
/// solo para la pieza principal de una pantalla (p. ej. la Palabra del día).
class VSurfaceCard extends StatelessWidget {
  const VSurfaceCard({
    super.key,
    required this.child,
    this.tone = VSurfaceTone.paper,
    this.framed = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = VerbumRadius.card,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VSurfaceTone tone;
  final bool framed;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color? border) = switch (tone) {
      VSurfaceTone.paper => (p.surface, null),
      VSurfaceTone.muted => (p.surfaceMuted, null),
      VSurfaceTone.ink => (p.inverse, null),
      VSurfaceTone.accent => (p.accentSoft, null),
      VSurfaceTone.butter => (p.butter, null),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: (borderColor ?? border) == null
          ? BorderSide.none
          : BorderSide(
              color: borderColor ?? border!,
              width: borderColor != null ? 1.5 : 1,
            ),
    );

    // ponytail: [framed] se conserva por compatibilidad; en "Camino claro"
    // la pieza principal se distingue por tamaño y sombra, no por marco.
    final content = Padding(padding: padding, child: child);

    Widget card = Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (tone == VSurfaceTone.paper) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: VerbumShadows.soft(p),
        ),
        child: card,
      );
    }

    // Dentro de una superficie en tinta, el texto e iconos pasan a claro.
    final themed = tone == VSurfaceTone.ink
        ? IconTheme.merge(
            data: IconThemeData(color: p.onInverse),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.onInverse),
              child: card,
            ),
          )
        : card;

    if (semanticLabel == null) return themed;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: themed,
    );
  }
}
