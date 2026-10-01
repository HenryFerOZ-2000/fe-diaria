import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_button.dart';
import 'v_icon.dart';

/// Mensaje centrado para cargas, errores o listas vacías.
class VEmptyState extends StatelessWidget {
  const VEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final VerbumIcons? icon;

  /// Muestra un indicador de progreso en lugar del icono.
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 30,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (icon != null)
            VIcon(icon!, weight: VIconWeight.duotone, size: 40, color: p.gold),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: type.heading.copyWith(fontSize: 19),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: type.body),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            VButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
