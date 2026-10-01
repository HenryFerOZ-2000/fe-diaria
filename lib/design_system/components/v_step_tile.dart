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
    final done = state == VStepState.done;
    final current = state == VStepState.current;
    // Tarjeta blanca (o mantequilla si es la de ahora) con el icono
    // centrado en su cuadro: salvia con check cuando está hecho.
    final bg = current ? p.butter : p.surface;
    final (Color boxBg, Color boxFg) = done
        ? (p.sage, p.surface)
        : current
        ? (Colors.white.withValues(alpha: .6), p.onButter)
        : (p.surfaceMuted, p.rubric);
    final stateLabel = switch (state) {
      VStepState.done => 'completado',
      VStepState.current => 'ahora',
      VStepState.upcoming => 'pendiente',
    };

    return Semantics(
      button: onTap != null,
      label: '$title, $stateLabel',
      excludeSemantics: true,
      child: Material(
        elevation: current ? 0 : 5,
        shadowColor: p.ink.withValues(alpha: .16),
        color: bg,
        borderRadius: BorderRadius.circular(VerbumRadius.tile - 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: boxBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: VIcon(
                    done ? VerbumIcons.check : icon,
                    size: 19,
                    color: boxFg,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: type.bodyStrong.copyWith(
                    fontSize: 12,
                    color: current ? p.onButter : p.ink,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: type.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: current ? p.onButter : p.inkSubtle,
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
