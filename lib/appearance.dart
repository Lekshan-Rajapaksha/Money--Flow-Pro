import 'package:flutter/material.dart';

const appearancePreferenceKey = 'appearanceMode';

ThemeData moneyFlowTheme(Brightness brightness) {
  const forest = Color(0xFF17604A);
  const lime = Color(0xFFD8F489);
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF111C18) : const Color(0xFFF6F8EF);
  final colors = ColorScheme.fromSeed(
    seedColor: forest,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFA6E1BE) : forest,
    onPrimary: dark ? const Color(0xFF112D21) : Colors.white,
    surface: dark ? const Color(0xFF192823) : Colors.white,
    onSurface: dark ? const Color(0xFFE6F1E9) : const Color(0xFF172B24),
    onSurfaceVariant: dark ? const Color(0xFFB0C3B8) : const Color(0xFF55655D),
    surfaceContainerHighest:
        dark ? const Color(0xFF2A3C33) : const Color(0xFFEDF2E8),
    outlineVariant: dark ? const Color(0xFF40564B) : const Color(0xFFE2E9DD),
    secondaryContainer: dark ? const Color(0xFF394D29) : lime,
    onSecondaryContainer: dark ? lime : const Color(0xFF172B24),
    error: dark ? const Color(0xFFFFB3BF) : const Color(0xFFAA3C51),
  );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colors.onSurface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.secondaryContainer,
      height: 68,
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(13)),
        borderSide: BorderSide.none,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? lime : forest,
      foregroundColor: dark ? colors.onPrimary : Colors.white,
    ),
  );
}
