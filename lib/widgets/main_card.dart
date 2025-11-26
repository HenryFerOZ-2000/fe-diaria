import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta principal reutilizable con diseño moderno
class MainCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final double borderRadius;
  final List<BoxShadow>? customShadows;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Widget? decoration;

  const MainCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius = AppRadius.lg,
    this.customShadows,
    this.border,
    this.gradient,
    this.onTap,
    this.decoration,
  });

  @override
  State<MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<MainCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surface);
    final shadows = widget.customShadows ??
        (isDark ? AppShadows.cardDark : AppShadows.card);

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.gradient == null ? bgColor : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border,
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: widget.child,
          ),
          if (widget.decoration != null)
            Positioned.fill(
              child: widget.decoration!,
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: card,
        ),
      );
    }

    return card;
  }
}

