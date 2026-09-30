import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import '../theme/app_theme.dart';
import 'main_card.dart';
import 'prayer_reading_experience.dart';
import 'package:verbum/design_system/design_system.dart';

/// Tarjeta reutilizable para mostrar oraciones con diseño elegante
class PrayerCard extends StatelessWidget {
  final String title;
  final String text;
  final String? reference;
  final VerbumIcons? icon;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final Color? accentColor;
  final bool openReaderOnTap;
  final ContentProvenance provenance;

  const PrayerCard({
    super.key,
    required this.title,
    required this.text,
    this.reference,
    this.icon,
    this.onShare,
    this.onFavorite,
    this.isFavorite = false,
    this.accentColor,
    this.openReaderOnTap = true,
    this.provenance = ContentProvenance.unverified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return MainCard(
      onTap: openReaderOnTap
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PrayerTextReadingScreen(
                  title: title,
                  text: text,
                  reference: reference,
                  provenance: provenance,
                ),
              ),
            )
          : null,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y acciones
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: VIcon(icon!, color: accent, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onShare != null)
                IconButton(
                  icon: const VIcon(VerbumIcons.shareNetwork),
                  onPressed: onShare,
                  color: colorScheme.primary,
                ),
              if (onFavorite != null)
                IconButton(
                  icon: VIcon(
                    isFavorite ? VerbumIcons.heart : VerbumIcons.heart,
                    color: isFavorite ? Colors.red : colorScheme.primary,
                  ),
                  onPressed: onFavorite,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Texto de la oración
          Text(
            text,
            maxLines: openReaderOnTap ? 4 : null,
            overflow: openReaderOnTap ? TextOverflow.ellipsis : null,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.7,
            ),
            textAlign: TextAlign.justify,
          ),
          if (openReaderOnTap) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'ABRIR MODO ORACIÓN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                VIcon(VerbumIcons.arrowUpRight, size: 18, color: accent),
              ],
            ),
          ],
          // Referencia si existe
          if (reference != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VIcon(VerbumIcons.quotes, weight: VIconWeight.fill, size: 16, color: accent),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    reference!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
