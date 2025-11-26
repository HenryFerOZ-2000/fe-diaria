import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_card.dart';

/// Tarjeta reutilizable para mostrar categorías con diseño moderno
class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconBgColor = iconColor ?? colorScheme.primary;
    final bgColor = backgroundColor ?? (theme.brightness == Brightness.dark 
        ? AppColors.surfaceDark 
        : AppColors.surface);

    return MainCard(
      onTap: onTap,
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono con fondo
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconBgColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Título
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Descripción
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Indicador de acción
          Row(
            children: [
              Text(
                'Ver más',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

