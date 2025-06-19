import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'selected_theme';
  AppTheme _currentTheme = AppThemes.universe;

  AppTheme get currentTheme => _currentTheme;
  ThemeType get currentType => _currentTheme.type;

  ThemeProvider() {
    _loadTheme();
  }

  void setTheme(ThemeType type) async {
    _currentTheme = AppThemes.byType(type);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, type.index);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_themeKey);
    if (idx != null && idx >= 0 && idx < ThemeType.values.length) {
      _currentTheme = AppThemes.byType(ThemeType.values[idx]);
      notifyListeners();
    }
  }
}
