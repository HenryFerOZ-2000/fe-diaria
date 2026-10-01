import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';
import 'v_surface_card.dart';

/// Cifra con etiqueta: "12 · Oraciones".
class VStatTile extends StatelessWidget {
  const VStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final VerbumIcons icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return VSurfaceCard(
      radius: VerbumRadius.tile + 2,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      semanticLabel: '$value $label',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIcon(
              icon,
              weight: VIconWeight.duotone,
              size: 22,
              color: iconColor ?? context.palette.gold,
            ),
            const SizedBox(height: 8),
            Text(value, style: type.title.copyWith(fontSize: 26)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.caption,
            ),
          ],
        ),
      ),
    );
  }
}
