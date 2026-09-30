import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';
import 'v_surface_card.dart';

/// Tile de categoría: icono duotono arriba, título y detalle abajo.
class VCategoryTile extends StatelessWidget {
  const VCategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final VerbumIcons icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return VSurfaceCard(
      onTap: onTap,
      radius: VerbumRadius.tile + 2,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VIcon(
              icon,
              weight: VIconWeight.duotone,
              size: 28,
              color: iconColor ?? context.palette.rubric,
            ),
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.bodyStrong,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.caption,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
