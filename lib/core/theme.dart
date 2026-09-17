// lib/core/theme.dart
// Modern medical-grade theme for Doctor and Patient interfaces

import 'package:flutter/material.dart';

class AppTheme {
  // MotionCare Visual Reference Brand Colors (Images 1 & 2)
  static const Color primaryGreen = Color(0xFF319F78); // MotionCare signature emerald/teal green
  static const Color primaryTeal = Color(0xFF319F78); // Backward-compatible alias
  static const Color primaryAccent = Color(0xFF45B58E);

  static const Color darkText = Color(0xFF18181B); // Deep neutral black for headings
  static const Color textMuted = Color(0xFF6B7280); // Secondary gray
  static const Color textSubtle = Color(0xFF9CA3AF); // Tagline and placeholder gray

  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF3F4F6); // Soft fill for inputs & chips
  static const Color cardBorder = Color(0xFFE5E7EB); // Hairline border
  static const Color inactiveTrack = Color(0xFFF1F3F5); // Switcher track
  static const Color pauseButtonBg = Color(0xFFEEF0F2); // Soft pause button

  // AI State Colors
  static const Color stateCorrect = Color(0xFF319F78);
  static const Color stateIncorrect = Color(0xFFEF4444);
  static const Color stateInsufficientVisibility = Color(0xFFF59E0B);

  // Backward-compatible aliases
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceBg = Color(0xFFF3F4F6);
  static const Color textLight = Color(0xFF18181B);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundWhite,
      primaryColor: primaryGreen,
      cardColor: backgroundWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryAccent,
        surface: surfaceGray,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          backgroundColor: backgroundWhite,
          side: const BorderSide(color: cardBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
