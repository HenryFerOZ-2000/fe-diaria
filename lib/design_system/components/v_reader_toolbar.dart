import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_back_button.dart';
import 'v_icon.dart';

/// Una acción de la barra de lectura.
class VReaderAction {
  const VReaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final VerbumIcons icon;
  final String label;
  final VoidCallback? onPressed;
}

/// Barra superior de toda pantalla de lectura (Biblia, oraciones, momentos):
/// regreso a la izquierda, rótulo centrado y las acciones agrupadas en una
/// sola cápsula a la derecha.
class VReaderToolbar extends StatelessWidget {
  const VReaderToolbar({
    super.key,
    required this.actions,
    this.label,
    this.onBack,
  });

  final String? label;
  final List<VReaderAction> actions;
  final VoidCallback? onBack;

  static const _height = 60.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            VBackButton(onPressed: onBack),
            const SizedBox(width: 8),
            // El rótulo ocupa el espacio libre entre ambos lados y se
            // centra en él: con tres acciones no se corta.
            Expanded(
              child: label == null
                  ? const SizedBox()
                  : Text(
                      label!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.type.rubric.copyWith(
                        color: p.inkSubtle,
                        letterSpacing: 1,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            if (actions.isNotEmpty)
              Material(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(VerbumRadius.control),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in actions)
                      Tooltip(
                        message: a.label,
                        child: Semantics(
                          button: true,
                          label: a.label,
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: a.onPressed,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: VIcon(
                                  a.icon,
                                  size: 20,
                                  color: a.onPressed == null
                                      ? p.inkSubtle
                                      : p.rubric,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
