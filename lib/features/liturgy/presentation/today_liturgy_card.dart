import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/liturgical_day.dart';
import 'liturgical_palette.dart';

class TodayLiturgyCard extends StatelessWidget {
  const TodayLiturgyCard({super.key, required this.day, required this.onTap});

  final LiturgicalDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final color = day.primary.colors.firstOrNull;
    final colorLabel = color == null
        ? 'Sin color indicado'
        : 'Color ${LiturgicalPalette.label(color)}';

    return Semantics(
      button: true,
      label: 'Hoy en la Iglesia. ${day.primary.name}. $colorLabel',
      excludeSemantics: true,
      onTap: onTap,
      child: VSurfaceCard(
        onTap: onTap,
        radius: VerbumRadius.card,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cuadro lavanda con la iglesia y, en la esquina, el color
            // litúrgico del día como único detalle de color.
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(VerbumRadius.control),
                    ),
                    child: VIcon(
                      VerbumIcons.church,
                      weight: VIconWeight.duotone,
                      size: 28,
                      color: p.rubric,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      key: const Key('liturgical_color_marker'),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color == null
                            ? p.line
                            : LiturgicalPalette.swatch(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          // El blanco litúrgico necesita contorno.
                          color: color == LiturgicalColor.white
                              ? p.line
                              : p.surface,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoy en la Iglesia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.primary.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.heading.copyWith(fontSize: 16, height: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    colorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
          ],
        ),
      ),
    );
  }
}
