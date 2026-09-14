import 'package:flutter/material.dart';

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
              icon: Icons.tune_rounded,
              tooltip: 'Configuración',
              onPressed:
                  onSettingsPressed ??
                  () => Navigator.of(context).pushNamed('/settings'),
            ),
          if (showSettings && showProfile) const SizedBox(width: 8),
          if (showProfile)
            VerbumHeaderButton(
              icon: Icons.person_outline_rounded,
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

class VerbumHeaderButton extends StatelessWidget {
  final IconData icon;
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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = emphasized
        ? scheme.primary
        : scheme.surface.withValues(alpha: dark ? .72 : .84);
    final foreground = emphasized ? scheme.onPrimary : scheme.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: emphasized
                ? scheme.primary.withValues(alpha: .75)
                : scheme.outlineVariant.withValues(alpha: .9),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
