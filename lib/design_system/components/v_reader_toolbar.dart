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
/// sola cápsula a la derecha. El rótulo queda centrado en la pantalla sin
/// importar cuántas acciones haya.
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (label != null)
              Padding(
                // Deja sitio a los botones de ambos lados.
                padding: EdgeInsets.symmetric(
                  horizontal: 44.0 * actions.length + 12,
                ),
                child: Text(
                  label!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.type.rubric.copyWith(
                    color: p.inkSubtle,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: VBackButton(onPressed: onBack),
            ),
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Material(
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
