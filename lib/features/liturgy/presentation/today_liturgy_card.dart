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
    final brightness = Theme.of(context).brightness;
    final color = day.primary.colors.firstOrNull;
    final accent = color == null
        ? p.line
        : LiturgicalPalette.accent(color, brightness);
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
        radius: VerbumRadius.tile,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const Key('liturgical_color_marker'),
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                  // El blanco litúrgico necesita contorno sobre papel.
                  border: color == LiturgicalColor.white
                      ? Border.all(color: p.line)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VRubricLabel(
                      'Hoy en la Iglesia',
                      icon: VerbumIcons.church,
                      color: color == null ? p.inkSubtle : accent,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      day.primary.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.heading.copyWith(fontSize: 19, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(colorLabel, style: type.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: VIcon(
                  VerbumIcons.caretRight,
                  size: 18,
                  color: p.inkSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
