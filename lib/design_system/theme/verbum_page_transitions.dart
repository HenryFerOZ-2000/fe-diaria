import 'package:flutter/material.dart';

/// Transición de página de la app: fade + slide sutil hacia arriba, aplicada
/// globalmente para que toda navegación quede animada igual.
const PageTransitionsTheme verbumPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _ModernPageTransitionsBuilder(),
    TargetPlatform.iOS: _ModernPageTransitionsBuilder(),
    TargetPlatform.macOS: _ModernPageTransitionsBuilder(),
    TargetPlatform.windows: _ModernPageTransitionsBuilder(),
    TargetPlatform.linux: _ModernPageTransitionsBuilder(),
  },
);

class _ModernPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ModernPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.85).animate(fadeOut),
          child: child,
        ),
      ),
    );
  }
}
