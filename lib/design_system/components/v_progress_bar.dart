import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Barra de progreso fina y animada.
class VProgressBar extends StatelessWidget {
  const VProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 4,
    this.semanticLabel,
  });

  /// Entre 0 y 1.
  final double value;
  final Color? color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()} %',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: p.lineSoft,
            color: color ?? p.gold,
          ),
        ),
      ),
    );
  }
}
