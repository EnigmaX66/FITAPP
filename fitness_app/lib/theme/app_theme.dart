import 'package:flutter/material.dart';

/// Paleta principal de FIT_PRO inspirada en interfaces deportivas oscuras.
class FitPalette {
  static const Color bgDark = Color(0xFF0B0E14);
  static const Color surfaceDark = Color(0xFF151A23);
  static const Color surfaceElevatedDark = Color(0xFF1D2432);
  static const Color navDark = Color(0xFF0F131B);
  static const Color borderDark = Color(0xFF232B3A);

  static const Color bgLight = Color(0xFFF4F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFEDF1F7);
  static const Color borderLight = Color(0xFFDDE3EE);

  static const Color orange = Color(0xFFFF6B1A);
  static const Color green = Color(0xFF39D96B);
  static const Color heartRed = Color(0xFFE05A5A);
  static const Color sleepLavender = Color(0xFF7B77A8);
  static const Color blue = Color(0xFF3B9EFF);
  static const Color pink = Color(0xFFE26EE5);
  static const Color yellow = Color(0xFFF5B731);
  static const Color teal = Color(0xFF2EC4B6);
  static const Color purple = Color(0xFF7C6CF0);

  static const Color textMuted = Color(0xFF8B94A7);

  static const List<Color> accentOptions = [
    orange,
    green,
    blue,
    purple,
  ];

  static const List<String> accentNames = [
    'Naranja Pro',
    'Verde Fit',
    'Azul Eléctrico',
    'Violeta Sport',
  ];
}

class AppTheme {
  static ThemeData build({required bool darkMode, required int accentIndex}) {
    final safeIdx = accentIndex.clamp(0, FitPalette.accentOptions.length - 1);
    final accent = FitPalette.accentOptions[safeIdx];

    if (darkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: FitPalette.bgDark,
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: FitPalette.green,
          surface: FitPalette.surfaceDark,
          onPrimary: Colors.white,
          onSurface: const Color(0xFFF3F6FC),
        ),
        cardColor: FitPalette.surfaceDark,
        dividerColor: FitPalette.borderDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: FitPalette.bgDark,
          foregroundColor: Color(0xFFF3F6FC),
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: FitPalette.navDark,
          selectedItemColor: accent,
          unselectedItemColor: FitPalette.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FitPalette.surfaceElevatedDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FitPalette.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FitPalette.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: FitPalette.bgLight,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: FitPalette.green,
        surface: FitPalette.surfaceLight,
      ),
      cardColor: FitPalette.surfaceLight,
      dividerColor: FitPalette.borderLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: FitPalette.bgLight,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FitPalette.surfaceLight,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitPalette.surfaceElevatedLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FitPalette.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FitPalette.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
