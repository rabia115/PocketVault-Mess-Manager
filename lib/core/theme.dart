import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Global Theme Mode Notifier (System / Light / Dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class PVColors {
  static const primary = Color(0xFF176B50);
  static const darkPrimary = Color(0xFF0F4C3A);
  static const lightCanvas = Color(0xFFF5F7F6);
  static const darkCanvas = Color(0xFF121A17);
  static const darkSurface = Color(0xFF1A2420);
  static const textLight = Color(0xFF1E2923);
  static const textDark = Color(0xFFE8F1EC);
}

class PVTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PVColors.lightCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PVColors.primary,
        brightness: Brightness.light,
        primary: PVColors.primary,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: PVColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PVColors.darkCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PVColors.primary,
        brightness: Brightness.dark,
        primary: PVColors.primary,
        surface: PVColors.darkSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: PVColors.darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: PVColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PVColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
