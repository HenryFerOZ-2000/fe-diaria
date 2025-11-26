import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_card.dart';

/// Tarjeta reutilizable para mostrar oraciones con diseño elegante
class PrayerCard extends StatelessWidget {
  final String title;
  final String text;
  final String? reference;
  final IconData? icon;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final Color? accentColor;

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return MainCard(
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
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 28,
                  ),
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
                  icon: const Icon(Icons.share_outlined),
                  onPressed: onShare,
                  color: colorScheme.primary,
                ),
              if (onFavorite != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.7,
            ),
            textAlign: TextAlign.justify,
          ),
          // Referencia si existe
          if (reference != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 16,
                    color: accent,
                  ),
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

