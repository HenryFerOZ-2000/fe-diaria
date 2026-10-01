import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../photos/verbum_photos.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Tarjeta destacada en periwinkle, con foto de fondo o icono de marca de
/// agua. Una por pantalla.
class VFeatureCard extends StatelessWidget {
  const VFeatureCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.watermark = VerbumIcons.handsPraying,
    this.photo,
    this.footer,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final VerbumIcons watermark;

  /// Foto de fondo bajo un velo periwinkle; sustituye a la marca de agua.
  final VerbumPhotos? photo;

  /// Contenido opcional al pie (progreso, botón…).
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final bg = p.inverse;
    final fg = p.onInverse;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(VerbumRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (photo != null) ...[
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Image.asset(photo!.asset, fit: BoxFit.cover),
                ),
              ),
              // Velo: legible arriba-izquierda, la foto respira abajo-derecha.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        bg.withValues(alpha: 0.96),
                        bg.withValues(alpha: 0.82),
                        bg.withValues(alpha: 0.35),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
            ] else
              Positioned(
                right: -30,
                bottom: -34,
                child: ExcludeSemantics(
                  child: VIcon(
                    watermark,
                    weight: VIconWeight.duotone,
                    size: 132,
                    color: fg.withValues(alpha: 0.14),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: type.rubric.copyWith(color: p.butter)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: type.title.copyWith(color: fg, fontSize: 30),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        body!,
                        style: type.body.copyWith(
                          color: fg.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 16), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
