import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// El único botón de regreso de la app: cuadro lavanda con flecha índigo.
/// Sobre fondos de color ([onColor]) pasa a vidrio translúcido.
class VBackButton extends StatelessWidget {
  const VBackButton({super.key, this.onPressed, this.onColor = false});

  /// Por defecto, `Navigator.maybePop`.
  final VoidCallback? onPressed;
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(VerbumRadius.control);
    return Tooltip(
      message: 'Volver',
      child: Semantics(
        button: true,
        label: 'Volver',
        excludeSemantics: true,
        child: Material(
          color: onColor ? p.onInverse.withValues(alpha: .16) : p.surfaceMuted,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed ?? () => Navigator.of(context).maybePop(),
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: VIcon(
                  VerbumIcons.caretLeft,
                  size: 20,
                  color: onColor ? p.onInverse : p.rubric,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
