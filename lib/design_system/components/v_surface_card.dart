import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';

enum VSurfaceTone {
  /// Papel con filete (por defecto).
  paper,

  /// Bloque de apoyo sin borde, un tono más oscuro que el fondo.
  muted,

  /// Invertido en tinta (estado completado / destacado).
  ink,

  /// Tinte del tiempo litúrgico.
  accent,
}

/// Superficie base de la app: plana, con filete fino, sin sombras.
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
      VSurfaceTone.paper => (p.surface, p.line),
      VSurfaceTone.muted => (p.surfaceMuted, null),
      VSurfaceTone.ink => (p.ink, null),
      VSurfaceTone.accent => (p.accentSoft, null),
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

    Widget content = Padding(padding: padding, child: child);
    if (framed) {
      content = Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius - 5),
                  border: Border.all(color: p.lineSoft),
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    final card = Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );

    // Dentro de una superficie en tinta, el texto e iconos pasan a claro.
    final themed = tone == VSurfaceTone.ink
        ? IconTheme.merge(
            data: IconThemeData(color: p.onInk),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.onInk),
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
