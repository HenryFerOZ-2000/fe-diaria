import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';
import 'v_step_tile.dart';
import 'v_surface_card.dart';

/// Número grande en serif para elegir capítulo, día de novena, etc.
class VNumberTile extends StatelessWidget {
  const VNumberTile({
    super.key,
    required this.number,
    required this.onTap,
    this.state = VStepState.upcoming,
    this.caption,
    this.semanticLabel,
  });

  final int number;
  final VStepState state;

  /// Texto pequeño sobre el número ("Día").
  final String? caption;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final current = state == VStepState.current;
    final done = state == VStepState.done;
    return VSurfaceCard(
      onTap: onTap,
      tone: current ? VSurfaceTone.butter : VSurfaceTone.paper,
      radius: VerbumRadius.tile,
      padding: EdgeInsets.zero,
      semanticLabel: semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (caption != null)
                Text(caption!, style: type.caption.copyWith(fontSize: 10.5)),
              Text(
                '$number',
                style: type.heading.copyWith(
                  fontSize: caption == null ? 21 : 28,
                  color: current ? p.onButter : (done ? p.inkMuted : p.ink),
                ),
              ),
            ],
          ),
          if (done || current)
            Positioned(
              right: 7,
              top: 6,
              child: VIcon(
                done ? VerbumIcons.checkCircle : VerbumIcons.bookmarkSimple,
                weight: VIconWeight.fill,
                size: 12,
                color: done ? p.sage : p.onButter,
              ),
            ),
        ],
      ),
    );
  }
}
