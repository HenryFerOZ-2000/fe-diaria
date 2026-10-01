import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';
import 'v_surface_card.dart';

/// Fila accionable: icono, rúbrica opcional, título, detalle y flecha.
/// Sirve para invitaciones, accesos directos y filas de ajustes.
class VActionTile extends StatelessWidget {
  const VActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.overline,
    this.subtitle,
    this.trailingIcon = VerbumIcons.arrowRight,
    this.tone = VSurfaceTone.muted,
    this.iconColor,
    this.onTap,
  });

  final VerbumIcons icon;
  final String title;
  final String? overline;
  final String? subtitle;
  final VerbumIcons? trailingIcon;
  final VSurfaceTone tone;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final onInk = tone == VSurfaceTone.ink;
    final titleColor = onInk ? p.onInverse : p.ink;
    final detailColor = onInk
        ? p.onInverse.withValues(alpha: 0.72)
        : p.inkMuted;
    final accent = iconColor ?? (onInk ? p.gold : p.rubric);

    return VSurfaceCard(
      tone: tone,
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          VIcon(icon, weight: VIconWeight.duotone, size: 28, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(
                    overline!,
                    style: type.rubric.copyWith(
                      color: accent,
                      fontSize: 9.5,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(title, style: type.bodyStrong.copyWith(color: titleColor)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption.copyWith(color: detailColor),
                  ),
                ],
              ],
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: onInk ? p.onInverse.withValues(alpha: 0.1) : p.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: VIcon(trailingIcon!, size: 15, color: titleColor),
            ),
          ],
        ],
      ),
    );
  }
}
