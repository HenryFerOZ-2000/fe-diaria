import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget para el encabezado del perfil con foto, nombre y estadísticas
class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final int streak;
  final int daysCompleted;
  final int likesReceived;
  final VoidCallback? onEditProfile;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.streak,
    required this.daysCompleted,
    required this.likesReceived,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Foto de perfil
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryDark,
                backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
                    ? NetworkImage(userAvatar!)
                    : null,
                child: userAvatar == null || userAvatar!.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Nombre
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '$streak',
                label: 'Racha',
                icon: Icons.local_fire_department,
              ),
              _StatItem(
                value: '$daysCompleted',
                label: 'Días',
                icon: Icons.calendar_today,
              ),
              _StatItem(
                value: '$likesReceived',
                label: 'Likes',
                icon: Icons.favorite,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Botón Editar perfil
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primaryDark, width: 2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryDark,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryDark.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

