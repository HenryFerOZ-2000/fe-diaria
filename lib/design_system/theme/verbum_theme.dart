import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/verbum_palette.dart';
import '../tokens/verbum_radius.dart';
import '../tokens/verbum_typography.dart';

/// Construye el [ThemeData] completo a partir de los tokens.
///
/// [accent] es el color del tiempo litúrgico; `null` mantiene el pan de oro.
ThemeData buildVerbumTheme({
  required Brightness brightness,
  Color? accent,
  PageTransitionsTheme? pageTransitionsTheme,
}) {
  final isDark = brightness == Brightness.dark;
  final palette = (isDark ? VerbumPalette.dark : VerbumPalette.light)
      .withAccent(accent);
  final type = VerbumTypography.fromPalette(palette);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.ink,
    onPrimary: palette.onInk,
    primaryContainer: palette.surfaceMuted,
    onPrimaryContainer: palette.ink,
    secondary: palette.gold,
    onSecondary: isDark ? palette.onInk : Colors.white,
    secondaryContainer: palette.goldSoft,
    onSecondaryContainer: palette.ink,
    tertiary: palette.accent,
    onTertiary: isDark ? palette.onInk : Colors.white,
    tertiaryContainer: palette.accentSoft,
    onTertiaryContainer: palette.ink,
    error: isDark ? const Color(0xFFF2A097) : const Color(0xFFB3261E),
    onError: isDark ? const Color(0xFF3A0B07) : Colors.white,
    errorContainer: isDark ? const Color(0xFF4A1A15) : const Color(0xFFF9DEDA),
    onErrorContainer: isDark
        ? const Color(0xFFF9DEDA)
        : const Color(0xFF410E0B),
    surface: palette.surface,
    onSurface: palette.ink,
    onSurfaceVariant: palette.inkMuted,
    surfaceContainerLowest: palette.background,
    surfaceContainerLow: palette.background,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surfaceMuted,
    surfaceContainerHighest: palette.surfaceMuted,
    outline: palette.line,
    outlineVariant: palette.lineSoft,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: palette.inverse,
    onInverseSurface: palette.onInverse,
    inversePrimary: palette.gold,
  );

  final baseText = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
  final textTheme = VerbumFonts.sansTextTheme(baseText).copyWith(
    displayLarge: type.display.copyWith(fontSize: 40),
    displayMedium: type.display,
    displaySmall: type.title,
    headlineLarge: type.title,
    headlineMedium: type.title.copyWith(fontSize: 24),
    headlineSmall: type.heading,
    titleLarge: type.bodyStrong.copyWith(fontSize: 18),
    titleMedium: type.bodyStrong.copyWith(fontSize: 16),
    titleSmall: type.bodyStrong,
    bodyLarge: type.body.copyWith(fontSize: 16, color: palette.ink),
    bodyMedium: type.body,
    bodySmall: type.caption.copyWith(fontSize: 12.5),
    labelLarge: type.button,
    labelMedium: type.bodyStrong.copyWith(fontSize: 13),
    labelSmall: type.caption.copyWith(fontWeight: FontWeight.w600),
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VerbumRadius.control),
  );
  final hairline = BorderSide(color: palette.line);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    dividerColor: palette.line,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: pageTransitionsTheme,
    textTheme: textTheme,
    extensions: [palette, type],
    iconTheme: IconThemeData(color: palette.ink, size: 22),
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: palette.ink),
      titleTextStyle: type.title.copyWith(fontSize: 26),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.card),
        side: hairline,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.emphasis,
        foregroundColor: palette.onEmphasis,
        disabledBackgroundColor: palette.surfaceMuted,
        disabledForegroundColor: palette.inkSubtle,
        elevation: 0,
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape,
        textStyle: type.button,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.emphasis,
        foregroundColor: palette.onEmphasis,
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape,
        textStyle: type.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.line, width: 1.2),
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape,
        textStyle: type.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.rubric,
        shape: shape,
        textStyle: type.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: type.body.copyWith(color: palette.inkSubtle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        borderSide: hairline,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        borderSide: hairline,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        borderSide: BorderSide(color: palette.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.emphasis,
      side: hairline,
      // El seleccionado va sobre énfasis: su texto y check deben contrastar.
      labelStyle: type.bodyStrong.copyWith(fontSize: 13, color: palette.ink),
      secondaryLabelStyle: type.bodyStrong.copyWith(
        fontSize: 13,
        color: palette.onEmphasis,
      ),
      checkmarkColor: palette.onEmphasis,
      shape: const StadiumBorder(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? palette.onEmphasis
            : palette.inkSubtle,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? palette.emphasis
            : palette.surfaceMuted,
      ),
      trackOutlineColor: WidgetStatePropertyAll(palette.line),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.gold,
      linearTrackColor: palette.lineSoft,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.inverse,
      contentTextStyle: type.bodyStrong.copyWith(color: palette.onInverse),
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VerbumRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.card),
      ),
      titleTextStyle: type.heading,
      contentTextStyle: type.body,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? palette.ink
              : palette.inkSubtle,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => type.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? palette.ink
              : palette.inkSubtle,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: palette.ink,
      unselectedItemColor: palette.inkSubtle,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
