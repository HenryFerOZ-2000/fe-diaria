import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';
import 'v_step_tile.dart';

/// Fila de un recorrido por días (camino espiritual, novena…).
/// [locked] desactiva el toque y muestra un candado.
class VStepRow extends StatelessWidget {
  const VStepRow({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    this.subtitle,
    this.locked = false,
    this.onTap,
  });

  final int number;
  final String title;
  final String? subtitle;
  final VStepState state;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final done = state == VStepState.done;
    final current = state == VStepState.current;
    final stateLabel = done
        ? 'completado'
        : locked
        ? 'bloqueado'
        : current
        ? 'siguiente'
        : 'disponible';

    return Semantics(
      button: !locked,
      label: 'Día $number, $title, $stateLabel',
      excludeSemantics: true,
      child: Opacity(
        opacity: locked ? .6 : 1,
        child: Material(
          color: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VerbumRadius.tile + 2),
            side: BorderSide(
              color: current ? p.rubric : p.line,
              width: current ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: locked ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? p.emphasis : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? p.emphasis
                            : current
                            ? p.rubric
                            : p.line,
                      ),
                    ),
                    child: done
                        ? VIcon(
                            VerbumIcons.check,
                            size: 17,
                            color: p.onEmphasis,
                          )
                        : Text(
                            '$number',
                            style: type.bodyStrong.copyWith(
                              color: current ? p.rubric : p.inkMuted,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: type.bodyStrong),
                        if (subtitle != null)
                          Text(subtitle!, style: type.caption),
                      ],
                    ),
                  ),
                  VIcon(
                    locked ? VerbumIcons.lockSimple : VerbumIcons.caretRight,
                    size: 17,
                    color: p.inkSubtle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
