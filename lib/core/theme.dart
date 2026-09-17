// lib/core/theme.dart
// Modern medical-grade theme for Doctor and Patient interfaces

import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0B0F17); // Obsidian Matte
  static const Color cardBg = Color(0xFF131A26); // Minimalist Flat Slate
  static const Color surfaceBg = Color(0xFF1A2234); // Elevated highlight
  static const Color cardBorder = Color(0xFF1E293B); // Subtle 1px boundary

  static const Color primaryTeal = Color(0xFF0EA5E9); // Sky/Cyan 500
  static const Color primaryAccent = Color(0xFF38BDF8); // Sky 400

  // AI State Colors (Specification v7 Section 12 & 31)
  static const Color stateCorrect = Color(0xFF10B981); // Emerald 500
  static const Color stateIncorrect = Color(0xFFEF4444); // Red 500
  static const Color stateInsufficientVisibility = Color(0xFFF59E0B); // Amber 500

  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryTeal,
      cardColor: cardBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: primaryAccent,
        surface: cardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: cardBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
