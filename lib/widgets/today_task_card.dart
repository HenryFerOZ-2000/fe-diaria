import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget para mostrar una tarea del día (versículo, oración, etc.)
/// Con estado HECHO o PENDIENTE y animación al completarse
class TodayTaskCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String duration;
  final bool isCompleted;
  final VoidCallback? onTap;
  final IconData icon;

  const TodayTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.isCompleted,
    this.onTap,
    required this.icon,
  });

  @override
  State<TodayTaskCard> createState() => _TodayTaskCardState();
}

class _TodayTaskCardState extends State<TodayTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    if (widget.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(TodayTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _animationController.forward();
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? (isDark
                        ? AppColors.primaryDark.withOpacity(0.2)
                        : AppColors.primaryLight.withOpacity(0.1))
                    : (isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: widget.isCompleted
                      ? AppColors.primaryLight
                      : (isDark
                          ? AppColors.outlineDark
                          : AppColors.outline),
                  width: widget.isCompleted ? 2 : 1,
                ),
                boxShadow: widget.isCompleted
                    ? [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : AppShadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    // Icono con estado
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.isCompleted
                            ? AppColors.primaryLight
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.background.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: widget.isCompleted
                          ? ScaleTransition(
                              scale: _checkmarkAnimation,
                              child: const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Contenido
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.isCompleted
                                        ? AppColors.primaryLight
                                        : null,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.background,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  widget.duration,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.onSurfaceVariantDark
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Indicador de estado
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      widget.isCompleted ? 'HECHO' : 'PENDIENTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.isCompleted
                            ? AppColors.primaryLight
                            : (isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariant),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

