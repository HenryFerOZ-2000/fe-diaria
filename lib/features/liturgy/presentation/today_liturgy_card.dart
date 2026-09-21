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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 14, 15),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: const Key('liturgical_color_marker'),
                      width: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(99),
                        border: color == LiturgicalColor.white
                            ? Border.all(color: colorScheme.outline, width: 1)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                              letterSpacing: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.primary.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MetadataPill(
                                icon: Icons.circle,
                                iconColor: accent,
                                label: colorLabel,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: onTap,
                                  iconAlignment: IconAlignment.end,
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Ver el día'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 44),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
