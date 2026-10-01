import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Opción seleccionable con icono y etiqueta (emociones, tradiciones…).
/// La elegida lleva filete rojo rúbrica y el icono en duotono.
class VChoiceTile extends StatelessWidget {
  const VChoiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final VerbumIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? p.accentSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VerbumRadius.tile),
          side: BorderSide(
            color: selected ? p.rubric : p.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(
                  icon,
                  weight: selected ? VIconWeight.duotone : VIconWeight.regular,
                  size: 28,
                  color: selected ? p.rubric : p.inkMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.type.caption.copyWith(
                    color: selected ? p.ink : p.inkMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
