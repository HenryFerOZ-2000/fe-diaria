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
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStatePropertyAll(
            palette.ink.withValues(alpha: 0.04),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: iconSize,
              color: states.contains(WidgetState.selected)
                  ? palette.ink
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
              color: selected ? palette.ink : palette.inkSubtle,
            );
          }),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.97),
            border: Border(top: BorderSide(color: palette.line)),
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
                    _destination(VerbumIcons.chatsCircle, 'Chat', 'Abrir chat'),
                    _destination(
                      VerbumIcons.usersThree,
                      'Comunidad',
                      'Abrir comunidad',
                    ),
                    _destination(
                      iconForDayHour(dayHourFor(now())),
                      'Hoy',
                      'Abrir hoy',
                    ),
                    _destination(
                      VerbumIcons.handsPraying,
                      'Oraciones',
                      'Abrir oraciones',
                    ),
                    _destination(
                      VerbumIcons.bookOpenText,
                      'Biblia',
                      'Abrir Biblia',
                    ),
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
