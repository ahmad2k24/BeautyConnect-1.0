import 'package:flutter/material.dart';

class ThemeController {
  // Private constructor
  ThemeController._internal();

  // Single global instance
  static final ThemeController _instance = ThemeController._internal();

  // Public accessor
  static ThemeController get instance => _instance;

  // ValueNotifier for theme
  final ValueNotifier<bool> isDark = ValueNotifier(false);

  void toggleTheme() {
    isDark.value = !isDark.value;
  }

  ThemeData get currentTheme =>
      isDark.value ? ThemeData.dark() : ThemeData.light();
}
