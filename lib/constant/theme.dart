import 'package:flutter/material.dart';

enum ThemeType { universe }

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
    background: Color(0xFF0B1120),
    gradient: [
      Color(0xFF0B1120), // Dark navy
      Color(0xFF1A1F35), // Slightly lighter navy
    ],
    primary: Color(0xFF6366F1), // Indigo
    accent: Color(0xFF8B5CF6), // Purple
    textColor: Colors.white,
    buttonColor: Color(0xFF6366F1),
    cardColor: Color(0xFF1E1640),
    borderColor: Color(0xFF6366F1),
    brightness: Brightness.dark,
    glass: true,
    showSpaceElements: true,
    showRainbowElements: false,
  );

  static const List<AppTheme> all = [universe];

  static AppTheme byType(ThemeType type) {
    switch (type) {
      case ThemeType.universe:
        return universe;
    }
  }
}

// Premium Gradient Definitions
class AppGradients {
  // Button Gradients
  static const primaryButton = LinearGradient(
    colors: [
      Color(0xFF6366F1), // Indigo
      Color(0xFFA855F7), // Purple
      Color(0xFFEC4899), // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryButton = LinearGradient(
    colors: [
      Color(0xFF3B82F6), // Blue
      Color(0xFF06B6D4), // Cyan
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Message Bubble Gradients
  static const userMessage = LinearGradient(
    colors: [
      Color(0xFF3B82F6), // Blue
      Color(0xFF06B6D4), // Cyan
      Color(0xFF14B8A6), // Teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const assistantMessage = LinearGradient(
    colors: [
      Color(0xFF8B5CF6), // Purple
      Color(0xFFA855F7), // Bright purple
      Color(0xFFEC4899), // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card Gradients
  static const premiumCard = LinearGradient(
    colors: [
      Color(0xFF1E1B4B), // Deep purple
      Color(0xFF312E81), // Rich purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassmorphicOverlay = LinearGradient(
    colors: [
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer/Glow Effects
  static const shimmerGradient = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x40FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Border Gradients
  static const borderGradient = LinearGradient(
    colors: [
      Color(0xFF6366F1),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Premium Color Palette
class AppColors {
  // Primary Colors
  static const indigo = Color(0xFF6366F1);
  static const purple = Color(0xFFA855F7);
  static const pink = Color(0xFFEC4899);
  static const blue = Color(0xFF3B82F6);
  static const cyan = Color(0xFF06B6D4);
  static const teal = Color(0xFF14B8A6);
  static const amber = Color(0xFFF59E0B);

  // Glow/Shimmer Colors
  static const glowPurple = Color(0x40A855F7);
  static const glowBlue = Color(0x403B82F6);
  static const glowPink = Color(0x40EC4899);
  static const glowCyan = Color(0x4006B6D4);

  // Glass Effects
  static const glassWhite = Color(0x15FFFFFF);
  static const glassBorder = Color(0x30FFFFFF);
  static const glassHighlight = Color(0x40FFFFFF);
}

// Visual Effect Constants
class AppEffects {
  // Blur
  static const double blurLight = 10.0;
  static const double blurMedium = 15.0;
  static const double blurHeavy = 20.0;

  // Border Width
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // Border Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // Shadows
  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 5,
        ),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Animation Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}
