import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Barra inferior: cinco botones cuadrados redondeados, sin texto (el
/// nombre va en tooltip y semántica). El activo se rellena en lavanda.
///
/// En "Hoy" (índice 0) Oraciones aparece como botón central en
/// mantequilla: una invitación a orar desde la portada.
class VerbumBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const VerbumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = [
    (VerbumIcons.house, 'Hoy'),
    (VerbumIcons.bookOpenText, 'Biblia'),
    (VerbumIcons.handsPraying, 'Oraciones'),
    (VerbumIcons.usersThree, 'Comunidad'),
    (VerbumIcons.chatsCircle, 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onHome = selectedIndex == 0;

    return Material(
      color: p.surface,
      elevation: 8,
      shadowColor: p.ink.withValues(alpha: 0.2),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavButton(
                      icon: _destinations[i].$1,
                      label: _destinations[i].$2,
                      selected: i == selectedIndex,
                      butter: onHome && i == 2,
                      onTap: () => onDestinationSelected(i),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.butter,
    required this.onTap,
  });

  final VerbumIcons icon;
  final String label;
  final bool selected;

  /// Botón central destacado (solo en "Hoy").
  final bool butter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg) = butter
        ? (p.butter, p.onButter)
        : selected
        ? (p.surfaceMuted, p.rubric)
        : (Colors.transparent, p.inkSubtle);
    final size = butter ? 60.0 : 50.0;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Center(
          child: Material(
            color: bg,
            elevation: butter ? 6 : 0,
            shadowColor: p.ink.withValues(alpha: 0.3),
            shape: butter
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VerbumRadius.control),
                  ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: VIcon(
                    icon,
                    size: butter ? 28 : 24,
                    weight: selected || butter
                        ? VIconWeight.fill
                        : VIconWeight.regular,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
