import 'package:flutter/material.dart';

/// Material 3 theme matching the Stitch mockups (teal palette, Plus Jakarta Sans).
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  /// Gradient used on the balance card (primary -> primary-container).
  static const List<Color> balanceGradient = [Color(0xFF004F45), Color(0xFF00695C)];

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF004F45),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF00695C),
    onPrimaryContainer: Color(0xFF94E5D5),
    secondary: Color(0xFF006A63),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF8BF1E6),
    onSecondaryContainer: Color(0xFF00201D),
    tertiary: Color(0xFF5D3F00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF7C5500),
    onTertiaryContainer: Color(0xFFFFCE7F),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF8F9FB),
    onSurface: Color(0xFF191C1E),
    onSurfaceVariant: Color(0xFF3E4946),
    outline: Color(0xFF6E7976),
    outlineVariant: Color(0xFFBEC9C5),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F4F6),
    surfaceContainer: Color(0xFFEDEEF0),
    surfaceContainerHigh: Color(0xFFE7E8EA),
    surfaceContainerHighest: Color(0xFFE1E2E4),
    inverseSurface: Color(0xFF2E3132),
    onInverseSurface: Color(0xFFF0F1F3),
    inversePrimary: Color(0xFF84D5C5),
    surfaceTint: Color(0xFF046B5E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static ThemeData light() {
    final radius = BorderRadius.circular(16);
    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: _scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF004F45),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: _scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: _scheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: _scheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: _scheme.error, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: _scheme.primary,
          foregroundColor: _scheme.onPrimary,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: _scheme.primary,
          backgroundColor: _scheme.surfaceContainerLowest,
          side: BorderSide(color: _scheme.outlineVariant),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _scheme.surfaceContainerLowest,
        indicatorColor: _scheme.secondaryContainer,
        elevation: 3,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: _scheme.outlineVariant,
    );
  }
}
