import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

enum VStepState { done, current, upcoming }

/// Paso de un recorrido (horas del día, días de un camino espiritual…).
///
/// * done: invertido en tinta con check.
/// * current: filete rojo rúbrica.
/// * upcoming: papel neutro.
class VStepTile extends StatelessWidget {
  const VStepTile({
    super.key,
    required this.icon,
    required this.title,
    required this.state,
    this.caption,
    this.onTap,
  });

  final VerbumIcons icon;
  final String title;
  final String? caption;
  final VStepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final (
      Color bg,
      Color fg,
      Color iconColor,
      BorderSide side,
    ) = switch (state) {
      VStepState.done => (
        p.emphasis,
        p.onEmphasis,
        p.onEmphasis,
        BorderSide.none,
      ),
      VStepState.current => (
        p.surface,
        p.ink,
        p.rubric,
        BorderSide(color: p.rubric, width: 1.5),
      ),
      VStepState.upcoming => (
        p.surface,
        p.ink,
        p.gold,
        BorderSide(color: p.line),
      ),
    };
    final stateLabel = switch (state) {
      VStepState.done => 'completado',
      VStepState.current => 'siguiente',
      VStepState.upcoming => 'pendiente',
    };

    return Semantics(
      button: onTap != null,
      label: '$title, $stateLabel',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VerbumRadius.tile),
          side: side,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VIcon(
                      icon,
                      weight: VIconWeight.duotone,
                      size: 22,
                      color: iconColor,
                    ),
                    const Spacer(),
                    if (state == VStepState.done)
                      VIcon(
                        VerbumIcons.checkCircle,
                        weight: VIconWeight.fill,
                        size: 17,
                        color: p.onEmphasis,
                      )
                    else if (state == VStepState.current)
                      VIcon(VerbumIcons.circle, size: 17, color: p.rubric),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodyStrong.copyWith(color: fg, fontSize: 13),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption.copyWith(
                      color: state == VStepState.done
                          ? p.onEmphasis.withValues(alpha: 0.7)
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
