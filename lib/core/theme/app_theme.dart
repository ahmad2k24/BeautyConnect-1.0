import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Brand Palette
  static const Color primaryPink = Color(0xFFE91E63); // main pink
  static const Color lightPink = Color(0xFFF8BBD0);
  static const Color darkPink = Color(0xFFC2185B);
  static const Color background = Color(0xFFFFF1F5);
  static const Color textDark = Colors.black87;
  static const Color textLight = Colors.white;

  // 🌟 Light Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryPink,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      secondary: darkPink,
      surface: Colors.white,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryPink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: textLight),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryPink,
      foregroundColor: textLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightPink.withOpacity(0.2),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryPink, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: lightPink, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textDark, fontSize: 16),
      bodyMedium: TextStyle(color: textDark, fontSize: 14),
      titleLarge: TextStyle(
        color: darkPink,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: lightPink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(8),
    ),
  );

  // 🌑 Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryPink,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: ColorScheme.dark(
      primary: primaryPink,
      secondary: lightPink,
      surface: const Color(0xFF1E1E1E),
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: textLight),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryPink,
      foregroundColor: textLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white10, // subtle fill for dark background
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryPink, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      hintStyle: TextStyle(color: Colors.grey[400]),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight, fontSize: 16),
      bodyMedium: TextStyle(color: textLight, fontSize: 14),
      titleLarge: TextStyle(
        color: lightPink,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(8),
    ),
  );
}
