import 'package:flutter/material.dart';

import '../design_system/theme/verbum_theme.dart';

/// Colores legados, remapeados a la paleta "Vitela y tinta".
///
/// Se conservan los nombres para las pantallas que aún no migran. Código nuevo:
/// usar `context.palette` (ver `lib/design_system`).
class AppColors {
  static const Color primary = Color(0xFF1E1915);
  static const Color primaryLight = Color(0xFFE3B866);
  static const Color primaryDark = Color(0xFF1E1915);
  static const Color primaryContainer = Color(0xFFEDE3D1);

  static const Color secondary = Color(0xFFB0823A);
  static const Color secondaryLight = Color(0xFFE8D5AE);
  static const Color secondaryDark = Color(0xFF7B5928);
  static const Color secondaryContainer = Color(0xFFF1E6CF);

  static const Color tertiary = Color(0xFF9C2A22);
  static const Color tertiaryLight = Color(0xFFE08A7F);
  static const Color tertiaryDark = Color(0xFF6E1D17);
  static const Color tertiaryContainer = Color(0xFFF3DDD6);

  static const Color surface = Color(0xFFFBF7EF);
  static const Color surfaceVariant = Color(0xFFEDE3D1);
  static const Color surfaceDark = Color(0xFF191C26);
  static const Color surfaceVariantDark = Color(0xFF232734);

  static const Color background = Color(0xFFF5EEE1);
  static const Color backgroundDark = Color(0xFF101219);

  static const Color onPrimary = Color(0xFFF5EEE1);
  static const Color onSecondary = Color(0xFF1E1915);
  static const Color onSurface = Color(0xFF1E1915);
  static const Color onSurfaceVariant = Color(0xFF5B5047);
  static const Color onSurfaceDark = Color(0xFFEDE6D8);
  static const Color onSurfaceVariantDark = Color(0xFFA39C8E);

  static const Color outline = Color(0xFFDCCFB9);
  static const Color outlineVariant = Color(0xFFE8DDCB);
  static const Color outlineDark = Color(0xFF2B2F3C);
  static const Color outlineVariantDark = Color(0xFF232734);

  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDA);
  static const Color success = Color(0xFF3D6B4F);
  static const Color successContainer = Color(0xFFDCE7DD);

  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.2);
}

/// Sombras estandarizadas
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}

/// Espaciado estandarizado
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius estandarizado
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 20.0;
  static const double xl = 26.0;
  static const double xxl = 34.0;
  static const double round = 999.0;
}

/// Elevaciones estandarizadas
class AppElevation {
  static const double none = 0.0;
  static const double small = 2.0;
  static const double medium = 4.0;
  static const double large = 8.0;
}

/// Transición de página moderna: fade + slide sutil hacia arriba.
/// Se aplica globalmente a través de [PageTransitionsTheme] para que
/// TODAS las navegaciones (Navigator.push con MaterialPageRoute/rutas
/// nombradas) queden animadas sin tocar cada pantalla individualmente.
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

const PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _ModernPageTransitionsBuilder(),
    TargetPlatform.iOS: _ModernPageTransitionsBuilder(),
    TargetPlatform.macOS: _ModernPageTransitionsBuilder(),
    TargetPlatform.windows: _ModernPageTransitionsBuilder(),
    TargetPlatform.linux: _ModernPageTransitionsBuilder(),
  },
);

/// Tema claro con el acento neutro. Para el acento litúrgico usar
/// [buildVerbumTheme] con `accent`.
ThemeData get lightTheme => buildVerbumTheme(
  brightness: Brightness.light,
  pageTransitionsTheme: appPageTransitionsTheme,
);

ThemeData get darkTheme => buildVerbumTheme(
  brightness: Brightness.dark,
  pageTransitionsTheme: appPageTransitionsTheme,
);
