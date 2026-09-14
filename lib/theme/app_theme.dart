import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores profesional y moderna
class AppColors {
  // Colores primarios - Morado litúrgico elegante
  static const Color primary = Color(0xFF493878);
  static const Color primaryLight = Color(0xFF8D7BC2);
  static const Color primaryDark = Color(0xFF261E45);
  static const Color primaryContainer = Color(0xFFEAE4F6);

  // Colores secundarios - Dorado cálido
  static const Color secondary = Color(0xFFB58A45);
  static const Color secondaryLight = Color(0xFFD8B875);
  static const Color secondaryDark = Color(0xFF7B5928);
  static const Color secondaryContainer = Color(0xFFF5EBD8);

  // Colores terciarios - Azul cielo suave
  static const Color tertiary = Color(0xFF5F8178);
  static const Color tertiaryLight = Color(0xFF93AEA6);
  static const Color tertiaryDark = Color(0xFF365A52);
  static const Color tertiaryContainer = Color(0xFFDDEAE6);

  // Colores de superficie
  static const Color surface = Color(0xFFFFFDF8);
  static const Color surfaceVariant = Color(0xFFF3EFE8);
  static const Color surfaceDark = Color(0xFF201C2B);
  static const Color surfaceVariantDark = Color(0xFF2C2738);

  // Colores de fondo
  static const Color background = Color(0xFFF8F4EC);
  static const Color backgroundDark = Color(0xFF15121D);

  // Colores de texto
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF1A1A2E);
  static const Color onSurface = Color(0xFF211D2C);
  static const Color onSurfaceVariant = Color(0xFF69616F);
  static const Color onSurfaceDark = Color(0xFFE8E8F0);
  static const Color onSurfaceVariantDark = Color(0xFFA5A5B5);

  // Colores de borde y outline
  static const Color outline = Color(0xFFD8D0C5);
  static const Color outlineVariant = Color(0xFFEAE4DA);
  static const Color outlineDark = Color(0xFF3A3445);
  static const Color outlineVariantDark = Color(0xFF2D2539);

  // Colores de error y éxito
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);

  // Colores de sombra
  static Color shadowLight = Colors.black.withValues(alpha: 0.08);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.12);
  static Color shadowDark = Colors.black.withValues(alpha: 0.24);
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
      color: AppColors.primary.withValues(alpha: 0.1),
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

/// Configuración de tema claro
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
    ),

    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: appPageTransitionsTheme,

    // Text Theme - Tipografía moderna con Poppins y Nunito
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      // Display (Títulos grandes)
      displayLarge: GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.4,
      ),

      // Headline (Títulos de sección)
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.4,
      ),

      // Title (Títulos de tarjetas)
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.5,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.5,
      ),

      // Body (Texto principal)
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.6,
        letterSpacing: 0.1,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.4,
      ),

      // Label (Etiquetas y botones)
      labelLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: AppColors.primary),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
        letterSpacing: 0.3,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppElevation.none,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppElevation.none;
          if (states.contains(WidgetState.disabled)) return AppElevation.none;
          if (states.contains(WidgetState.hovered)) return AppElevation.medium;
          return AppElevation.small;
        }),
        shadowColor: const WidgetStatePropertyAll(AppColors.primary),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: AppColors.primary, width: 2);
          }
          return const BorderSide(color: AppColors.primary, width: 1.5);
        }),
        overlayColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: 0.08),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        overlayColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: 0.08),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      elevation: AppElevation.large,
      type: BottomNavigationBarType.fixed,
    ),

    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      elevation: 0,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        );
      }),
    ),
  );
}

/// Configuración de tema oscuro
ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surfaceDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
      onSurface: AppColors.onSurfaceDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: appPageTransitionsTheme,

    // Text Theme - Tipografía moderna con Poppins y Nunito
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          // Display (Títulos grandes)
          displayLarge: GoogleFonts.nunito(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceDark,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          displayMedium: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceDark,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          displaySmall: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceDark,
            height: 1.4,
          ),

          // Headline (Títulos de sección)
          headlineLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight,
            letterSpacing: 0.2,
            height: 1.4,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
            height: 1.4,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
            height: 1.4,
          ),

          // Title (Títulos de tarjetas)
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
            height: 1.5,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
            height: 1.5,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
            height: 1.5,
          ),

          // Body (Texto principal)
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceDark,
            height: 1.6,
            letterSpacing: 0.1,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariantDark,
            height: 1.5,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariantDark,
            height: 1.4,
          ),

          // Label (Etiquetas y botones)
          labelLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
            letterSpacing: 0.3,
          ),
          labelMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelSmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.primaryLight),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurfaceDark,
        letterSpacing: 0.3,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppElevation.none,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.outlineDark),
      ),
      color: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppElevation.none;
          if (states.contains(WidgetState.disabled)) return AppElevation.none;
          if (states.contains(WidgetState.hovered)) return AppElevation.medium;
          return AppElevation.small;
        }),
        shadowColor: const WidgetStatePropertyAll(AppColors.primaryLight),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: AppColors.primaryLight, width: 2);
          }
          return const BorderSide(color: AppColors.primaryLight, width: 1.5);
        }),
        overlayColor: WidgetStatePropertyAll(
          AppColors.primaryLight.withValues(alpha: 0.12),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        overlayColor: WidgetStatePropertyAll(
          AppColors.primaryLight.withValues(alpha: 0.12),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outlineDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outlineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.onSurfaceVariantDark,
      elevation: AppElevation.large,
      type: BottomNavigationBarType.fixed,
    ),

    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.primaryDark,
      elevation: 0,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.secondaryLight
              : AppColors.onSurfaceVariantDark,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariantDark,
        );
      }),
    ),
  );
}
