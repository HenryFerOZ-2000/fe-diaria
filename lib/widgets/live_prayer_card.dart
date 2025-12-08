import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget para mostrar una tarjeta de oración en vivo en el feed
class LivePrayerCard extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String prayerText;
  final int likes;
  final int comments;
  final VoidCallback? onJoinPrayer;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const LivePrayerCard({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.prayerText,
    required this.likes,
    required this.comments,
    this.onJoinPrayer,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con usuario
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                  backgroundImage: userAvatar.isNotEmpty
                      ? NetworkImage(userAvatar)
                      : null,
                  child: userAvatar.isEmpty
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Hace 5 min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Texto de la oración
            Text(
              prayerText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Botón Unirse a la oración
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoinPrayer,
                icon: const Icon(Icons.favorite, size: 20),
                label: const Text('Unirse a la oración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Acciones (likes y comentarios)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                  onPressed: onLike,
                ),
                Text(
                  '$likes',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: Icon(
                    Icons.comment_outlined,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                  onPressed: onComment,
                ),
                Text(
                  '$comments',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

