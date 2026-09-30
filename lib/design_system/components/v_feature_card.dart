import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Tarjeta destacada en tinta con icono de marca de agua. Una por pantalla.
class VFeatureCard extends StatelessWidget {
  const VFeatureCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.watermark = VerbumIcons.handsPraying,
    this.footer,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final VerbumIcons watermark;

  /// Contenido opcional al pie (progreso, botón…).
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // En modo noche la tinta es clara; la tarjeta usa la superficie elevada
    // para no deslumbrar.
    final bg = dark ? p.surfaceMuted : p.ink;
    final fg = dark ? p.ink : p.onInk;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(VerbumRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -34,
              child: ExcludeSemantics(
                child: VIcon(
                  watermark,
                  weight: VIconWeight.duotone,
                  size: 132,
                  color: p.gold.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: type.rubric.copyWith(color: p.gold),
                  ),
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
                          color: fg.withValues(alpha: 0.74),
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
