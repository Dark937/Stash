import 'package:flutter/material.dart';

class AppTheme {
  // Softer Dark aesthetic (slightly lighter than pure OLED)
  static const Color background = Color(0xFF111116); 
  static const Color surface = Color(0xFF1B1B22);
  static const Color surfaceLighter = Color(0xFF24242E);
  
  // Custom Lake Teal requested by user
  static const Color lakeTeal = Color(0xFF389F93); // Slightly more vibrant
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: lakeTeal,
      scaffoldBackgroundColor: background, 
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lakeTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: Colors.white30, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: lakeTeal,
        secondary: lakeTeal,
        surface: surface,
      ),
    );
  }

  static ThemeData get lightTheme {
    return darkTheme; // Force Dark theme everywhere
  }
}
