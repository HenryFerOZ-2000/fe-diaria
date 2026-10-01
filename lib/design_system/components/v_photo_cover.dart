import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';

/// Portada a sangre con foto y velo: legible arriba y abajo, la foto
/// respira en el centro y el borde inferior se funde con el fondo de la
/// página. Sobre la foto los tonos son fijos (Tinta de la paleta).
class VPhotoCover extends StatelessWidget {
  const VPhotoCover({
    super.key,
    required this.image,
    required this.child,
    this.minHeight = 360,
    this.bottomPadding = 40,
  });

  /// `AssetImage` o `NetworkImage` (p. ej. la foto de una comunidad).
  final ImageProvider image;

  /// Contenido sobre la foto; ya va dentro de la zona segura.
  final Widget child;
  final double minHeight;
  final double bottomPadding;

  static const _tinta = Color(0xFF22245A);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image(
                image: image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: p.inverse),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _tinta.withValues(alpha: .55),
                    _tinta.withValues(alpha: .15),
                    _tinta.withValues(alpha: .72),
                    p.background,
                  ],
                  stops: const [0, .32, .8, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                8,
                VerbumSpace.gutter,
                bottomPadding,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
