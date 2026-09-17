// lib/core/theme.dart
// Modern medical-grade theme for Doctor and Patient interfaces

import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color cardBg = Color(0xFF1E293B); // Slate 800
  static const Color surfaceBg = Color(0xFF334155); // Slate 700

  static const Color primaryTeal = Color(0xFF0EA5E9); // Sky 500
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
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
