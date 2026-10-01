import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../features/today/application/today_schedule.dart';
import '../features/today/presentation/day_hour_icons.dart';

class VerbumBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Reloj inyectable para tests.
  final DateTime Function() now;

  const VerbumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.now = DateTime.now,
  });

  static NavigationDestination _destination(
    VerbumIcons icon,
    String label,
    String tooltip,
  ) {
    return NavigationDestination(
      tooltip: tooltip,
      icon: VIcon(icon),
      selectedIcon: VIcon(icon, weight: VIconWeight.fill),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final veryCompact = constraints.maxWidth < 330;
        final iconSize = veryCompact ? 21.0 : (compact ? 22.0 : 24.0);
        final labelSize = veryCompact ? 9.0 : (compact ? 9.8 : 10.5);

        final navigationTheme = NavigationBarThemeData(
          height: veryCompact ? 58 : 62,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // El botón central ya es su propio indicador.
          indicatorColor: selectedIndex == 2
              ? Colors.transparent
              : palette.accentSoft,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VerbumRadius.control),
          ),
          overlayColor: WidgetStatePropertyAll(
            palette.ink.withValues(alpha: 0.04),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: iconSize,
              color: states.contains(WidgetState.selected)
                  ? palette.rubric
                  : palette.inkSubtle,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return type.caption.copyWith(
              fontSize: labelSize,
              height: 1.05,
              letterSpacing: veryCompact ? -0.2 : 0,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? palette.rubric : palette.inkSubtle,
            );
          }),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            boxShadow: VerbumShadows.subtle(palette),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: NavigationBarTheme(
              data: navigationTheme,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1,
                maxScaleFactor: 1.15,
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  animationDuration: const Duration(milliseconds: 220),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    _destination(
                      iconForDayHour(dayHourFor(now())),
                      'Hoy',
                      'Abrir hoy',
                    ),
                    _destination(
                      VerbumIcons.bookOpenText,
                      'Biblia',
                      'Abrir Biblia',
                    ),
                    // Oraciones: el botón central, siempre en mantequilla.
                    NavigationDestination(
                      tooltip: 'Abrir oraciones',
                      icon: _ButterDot(
                        child: VIcon(
                          VerbumIcons.handsPraying,
                          color: palette.onButter,
                        ),
                      ),
                      selectedIcon: _ButterDot(
                        child: VIcon(
                          VerbumIcons.handsPraying,
                          weight: VIconWeight.fill,
                          color: palette.onButter,
                        ),
                      ),
                      label: 'Oraciones',
                    ),
                    _destination(
                      VerbumIcons.usersThree,
                      'Comunidad',
                      'Abrir comunidad',
                    ),
                    _destination(VerbumIcons.chatsCircle, 'Chat', 'Abrir chat'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ButterDot extends StatelessWidget {
  const _ButterDot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.butter,
        shape: BoxShape.circle,
        boxShadow: VerbumShadows.subtle(p),
      ),
      child: child,
    );
  }
}
