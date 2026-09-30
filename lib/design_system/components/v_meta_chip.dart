import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';

/// Dato breve con icono: "1 min", "Día 4 de 9", "Opcional".
class VMetaChip extends StatelessWidget {
  const VMetaChip({super.key, required this.label, this.icon, this.color});

  final String label;
  final VerbumIcons? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            VIcon(icon!, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: context.type.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
