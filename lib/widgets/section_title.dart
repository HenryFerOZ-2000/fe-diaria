import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Título de sección con diseño moderno
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final TextAlign textAlign;
  final Color? color;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.padding,
    this.textAlign = TextAlign.left,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleColor = color ?? colorScheme.primary;

    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: titleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: titleColor, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: titleColor,
            ),
            textAlign: textAlign,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: textAlign,
            ),
          ],
        ],
      ),
    );
  }
}

