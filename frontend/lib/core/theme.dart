import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF7C3AED);    // violet
  static const _secondary = Color(0xFF06B6D4);   // cyan
  static const _background = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _surfaceVariant = Color(0xFF1E1E2E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          secondary: _secondary,
          surface: _surface,
          background: _background,
        ),
        cardTheme: CardTheme(
          color: _surfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Color(0xFFB0B0C0)),
        ),
      );
}
