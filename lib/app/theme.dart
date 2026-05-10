import 'package:flutter/material.dart';

abstract class AdenColors {
  static const bg = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1E3A8A);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFF3B82F6);
  static const surface = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMid = Color(0xFF475569);
  static const textLight = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const divider = Color(0xFFE2E8F0);

  static const gradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract class AdenTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdenColors.primary,
        brightness: Brightness.light,
        primary: AdenColors.primary,
        secondary: AdenColors.accent,
        surface: AdenColors.surface,
      ),
      scaffoldBackgroundColor: AdenColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AdenColors.bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AdenColors.textDark),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          color: AdenColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdenColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
      ),
      cardTheme: CardThemeData(
        color: AdenColors.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AdenColors.divider),
        ),
      ),
    );
  }
}
