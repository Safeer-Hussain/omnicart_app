import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00E676),
    brightness: Brightness.dark,
    primary: const Color(0xFF00E676),
    onPrimary: const Color(0xFF00391A),
    primaryContainer: const Color(0xFF005228),
    onPrimaryContainer: const Color(0xFF6BFF9E),
    secondary: const Color(0xFF00B0FF),
    onSecondary: const Color(0xFF00325B),
    secondaryContainer: const Color(0xFF00497E),
    onSecondaryContainer: const Color(0xFFBCE3FF),
    tertiary: const Color(0xFFFF6E40),
    onTertiary: const Color(0xFF5A1400),
    tertiaryContainer: const Color(0xFF7E2200),
    onTertiaryContainer: const Color(0xFFFFDBCF),
    surface: const Color(0xFF0D1217),
    onSurface: const Color(0xFFE2E7ED),
    surfaceContainerLowest: const Color(0xFF070B0E),
    surfaceContainerLow: const Color(0xFF12181F),
    surfaceContainer: const Color(0xFF171F27),
    surfaceContainerHigh: const Color(0xFF1E2833),
    surfaceContainerHighest: const Color(0xFF263340),
    onSurfaceVariant: const Color(0xFF9EABB8),
    outline: const Color(0xFF435160),
    outlineVariant: const Color(0xFF2E3A46),
    error: const Color(0xFFFF5252),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
  );

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00897B),
    brightness: Brightness.light,
    primary: const Color(0xFF00897B),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFA7F0E4),
    onPrimaryContainer: const Color(0xFF00201C),
    secondary: const Color(0xFF0288D1),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFBCE3FF),
    onSecondaryContainer: const Color(0xFF001E35),
    tertiary: const Color(0xFFE64A19),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFFFDBCF),
    onTertiaryContainer: const Color(0xFF380D00),
    surface: const Color(0xFFF7F9FB),
    onSurface: const Color(0xFF161D24),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFEFF2F5),
    surfaceContainer: const Color(0xFFE5E9EE),
    surfaceContainerHigh: const Color(0xFFDCE1E7),
    surfaceContainerHighest: const Color(0xFFD3D9E0),
    onSurfaceVariant: const Color(0xFF4C5B6A),
    outline: const Color(0xFF7B8A99),
    outlineVariant: const Color(0xFFC3CBD4),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: darkColorScheme.surface,
    cardTheme: CardThemeData(
      color: darkColorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkColorScheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkColorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: darkColorScheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkColorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.error, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkColorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: lightColorScheme.surface,
    cardTheme: CardThemeData(
      color: lightColorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lightColorScheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: lightColorScheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.error, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: lightColorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
