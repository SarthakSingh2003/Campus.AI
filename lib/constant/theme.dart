import 'package:flutter/material.dart';

enum ThemeType { universe, rainbow, glass }

class AppTheme {
  final ThemeType type;
  final String name;
  final Color background;
  final List<Color> gradient;
  final Color primary;
  final Color accent;
  final Color textColor;
  final Color buttonColor;
  final Color cardColor;
  final Color borderColor;
  final Brightness brightness;
  final bool glass;
  final bool showSpaceElements;
  final bool showRainbowElements;

  const AppTheme({
    required this.type,
    required this.name,
    required this.background,
    required this.gradient,
    required this.primary,
    required this.accent,
    required this.textColor,
    required this.buttonColor,
    required this.cardColor,
    required this.borderColor,
    required this.brightness,
    this.glass = false,
    this.showSpaceElements = false,
    this.showRainbowElements = false,
  });
}

class AppThemes {
  static const universe = AppTheme(
    type: ThemeType.universe,
    name: 'Universe',
    background: Color(0xFF0B0B2A),
    gradient: [
      Color(0xFF0B0B2A),
      Color(0xFF1A1A3A),
      Color(0xFF2D1B69),
      Color(0xFF1B1B3A),
    ],
    primary: Color(0xFF4F46E5),
    accent: Color(0xFF7C3AED),
    textColor: Colors.white,
    buttonColor: Color(0xFF4F46E5),
    cardColor: Color(0xFF1A1A3A),
    borderColor: Color(0xFF7C3AED),
    brightness: Brightness.dark,
    glass: false,
    showSpaceElements: true,
    showRainbowElements: false,
  );

  static const rainbow = AppTheme(
    type: ThemeType.rainbow,
    name: 'Rainbow',
    background: Color(0xFFEC4899),
    gradient: [
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
    ],
    primary: Color(0xFFEC4899),
    accent: Color(0xFFF59E0B),
    textColor: Colors.white,
    buttonColor: Color(0xFFF59E0B),
    cardColor: Color(0xFF7C3AED),
    borderColor: Color(0xFF4F46E5),
    brightness: Brightness.light,
    glass: false,
    showSpaceElements: false,
    showRainbowElements: true,
  );

  static const glass = AppTheme(
    type: ThemeType.glass,
    name: 'Glass',
    background: Color(0xFF181C23),
    gradient: [
      Color(0xFF232526),
      Color(0xFF181C23),
      Color(0xFF232526),
    ],
    primary: Color(0xFF232526),
    accent: Color(0xFF4F46E5),
    textColor: Colors.white,
    buttonColor: Color(0xFF4F46E5),
    cardColor: Color(0xFF232526),
    borderColor: Color(0xFF4F46E5),
    brightness: Brightness.dark,
    glass: true,
    showSpaceElements: false,
    showRainbowElements: false,
  );

  static const List<AppTheme> all = [universe, rainbow, glass];

  static AppTheme byType(ThemeType type) {
    switch (type) {
      case ThemeType.universe:
        return universe;
      case ThemeType.rainbow:
        return rainbow;
      case ThemeType.glass:
        return glass;
    }
  }
}
