import 'package:flutter/material.dart';

import '../domain/liturgical_day.dart';
import 'liturgical_palette.dart';

class TodayLiturgyCard extends StatelessWidget {
  const TodayLiturgyCard({super.key, required this.day, required this.onTap});

  final LiturgicalDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = day.primary.colors.firstOrNull;
    final accent = color == null
        ? colorScheme.outline
        : LiturgicalPalette.accent(color, theme.brightness);
    final colorLabel = color == null
        ? 'Sin color indicado'
        : 'Color ${LiturgicalPalette.label(color)}';

    return Semantics(
      button: true,
      label: 'Hoy en la Iglesia. ${day.primary.name}. $colorLabel',
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.10 : 0.07,
            ),
            colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        border: color == LiturgicalColor.white
                            ? Border.all(color: colorScheme.outline, width: 1)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOY EN LA IGLESIA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            day.primary.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 7, color: accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  colorLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
