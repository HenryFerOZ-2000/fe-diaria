import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Acciones canónicas de los encabezados de Verbum.
/// Mantiene iconografía, tamaño, orden y superficie iguales en toda la app.
class VerbumHeaderActions extends StatelessWidget {
  final bool showSettings;
  final bool showProfile;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;

  const VerbumHeaderActions({
    super.key,
    this.showSettings = true,
    this.showProfile = true,
    this.padding = const EdgeInsets.only(right: 12),
    this.onSettingsPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSettings)
            VerbumHeaderButton(
              icon: VerbumIcons.slidersHorizontal,
              tooltip: 'Configuración',
              onPressed:
                  onSettingsPressed ??
                  () => Navigator.of(context).pushNamed('/settings'),
            ),
          if (showSettings && showProfile) const SizedBox(width: 8),
          if (showProfile)
            VerbumHeaderButton(
              icon: VerbumIcons.user,
              tooltip: 'Mi perfil',
              emphasized: true,
              onPressed:
                  onProfilePressed ??
                  () => Navigator.of(context).pushNamed('/profile'),
            ),
        ],
      ),
    );
  }
}

/// Botón de cabecera: círculo con filete, o en tinta si [emphasized].
class VerbumHeaderButton extends StatelessWidget {
  final VerbumIcons icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool emphasized;

  const VerbumHeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return VIconButton(
      icon: icon,
      semanticLabel: tooltip,
      onPressed: onPressed,
      variant: emphasized
          ? VIconButtonVariant.solid
          : VIconButtonVariant.outlined,
    );
  }
}

/// Configuración a la izquierda de la barra en las pestañas principales
/// (el perfil queda a la derecha), como en las portadas con foto.
class VerbumSettingsButton extends StatelessWidget {
  const VerbumSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return VerbumHeaderButton(
      icon: VerbumIcons.slidersHorizontal,
      tooltip: 'Configuración',
      onPressed: () => Navigator.of(context).pushNamed('/settings'),
    );
  }
}
