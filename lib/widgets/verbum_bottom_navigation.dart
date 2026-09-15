import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerbumBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const VerbumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      tooltip: 'Abrir chat',
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Chat',
    ),
    NavigationDestination(
      tooltip: 'Abrir comunidad',
      icon: Icon(Icons.groups_2_outlined),
      selectedIcon: Icon(Icons.groups_2_rounded),
      label: 'Comunidad',
    ),
    NavigationDestination(
      tooltip: 'Abrir hoy',
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome_rounded),
      label: 'Hoy',
    ),
    NavigationDestination(
      tooltip: 'Abrir oraciones',
      icon: Icon(Icons.favorite_border_rounded),
      selectedIcon: Icon(Icons.favorite_rounded),
      label: 'Oraciones',
    ),
    NavigationDestination(
      tooltip: 'Abrir Biblia',
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Biblia',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final veryCompact = constraints.maxWidth < 330;
        final horizontalMargin = veryCompact
            ? 5.0
            : compact
            ? 8.0
            : 12.0;
        final barHeight = veryCompact
            ? 59.0
            : compact
            ? 61.0
            : 64.0;
        final iconSize = veryCompact
            ? 19.0
            : compact
            ? 20.0
            : 21.5;
        final labelSize = veryCompact
            ? 8.4
            : compact
            ? 9.2
            : 10.4;

        final navigationTheme = NavigationBarThemeData(
          height: barHeight,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: scheme.primary.withValues(alpha: dark ? .24 : .12),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: iconSize,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: .86),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: labelSize,
              height: 1.05,
              letterSpacing: veryCompact ? -.24 : -.12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: .9),
            );
          }),
        );

        return SafeArea(
          minimum: EdgeInsets.fromLTRB(
            horizontalMargin,
            3,
            horizontalMargin,
            8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF262130).withValues(alpha: .98)
                  : const Color(0xFFFFFCF7).withValues(alpha: .99),
              borderRadius: BorderRadius.circular(compact ? 20 : 23),
              border: Border.all(
                color: scheme.outline.withValues(alpha: dark ? .18 : .12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .26 : .1),
                  blurRadius: compact ? 18 : 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 19 : 22),
              child: NavigationBarTheme(
                data: navigationTheme,
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: 1,
                  maxScaleFactor: 1.15,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    animationDuration: const Duration(milliseconds: 260),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: _destinations,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
