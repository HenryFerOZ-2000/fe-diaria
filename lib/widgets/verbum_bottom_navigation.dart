import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Barra inferior "vidrio nocturno": una cápsula en tinta translúcida que
/// flota sobre el contenido, con iconos claros y un punto mantequilla bajo
/// la pestaña activa. Oraciones sobresale al centro en un círculo
/// mantequilla, siempre.
///
/// Los nombres van en tooltip y semántica.
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

  /// Índice de Oraciones, el botón central.
  static const _center = 2;

  static const _barHeight = 66.0;
  static const _centerSize = 58.0;

  /// Cuánto sobresale el botón central por encima de la cápsula.
  static const _rise = 22.0;

  // Tinta de la paleta: igual en modo claro y oscuro.
  static const _tinta = Color(0xFF22245A);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // De noche la tinta se perdería en el fondo: un tono más claro y un
    // filete la despegan.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final capsule = dark ? p.surfaceMuted : _tinta;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: SizedBox(
          height: _barHeight + _rise,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // La cápsula de vidrio.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: _tinta.withValues(alpha: .35),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: capsule.withValues(alpha: dark ? .94 : .84),
                          borderRadius: BorderRadius.circular(_barHeight / 2),
                          border: dark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: .08),
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            for (var i = 0; i < _destinations.length; i++)
                              Expanded(
                                child: i == _center
                                    // Hueco para el botón que sobresale.
                                    ? const SizedBox()
                                    : _NavButton(
                                        icon: _destinations[i].$1,
                                        label: _destinations[i].$2,
                                        selected: i == selectedIndex,
                                        dot: p.butter,
                                        onTap: () => onDestinationSelected(i),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Oraciones: círculo mantequilla que sobresale, con un aro del
              // color de la página para despegarlo de la cápsula.
              Positioned(
                top: 0,
                child: _PrayButton(
                  size: _centerSize,
                  selected: selectedIndex == _center,
                  ring: p.background,
                  butter: p.butter,
                  onButter: p.onButter,
                  onTap: () => onDestinationSelected(_center),
                ),
              ),
            ],
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
    required this.dot,
    required this.onTap,
  });

  final VerbumIcons icon;
  final String label;
  final bool selected;
  final Color dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          highlightColor: Colors.transparent,
          splashColor: Colors.white.withValues(alpha: .12),
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VIcon(
                  icon,
                  size: 24,
                  weight: selected ? VIconWeight.fill : VIconWeight.regular,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: .55),
                ),
                if (selected)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
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

class _PrayButton extends StatelessWidget {
  const _PrayButton({
    required this.size,
    required this.selected,
    required this.ring,
    required this.butter,
    required this.onButter,
    required this.onTap,
  });

  final double size;
  final bool selected;
  final Color ring;
  final Color butter;
  final Color onButter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Oraciones',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Oraciones',
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
          child: Material(
            color: butter,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: const Color(0xFF3A2F05).withValues(alpha: .5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: VIcon(
                    VerbumIcons.handsPraying,
                    size: 28,
                    weight: VIconWeight.fill,
                    color: onButter,
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
