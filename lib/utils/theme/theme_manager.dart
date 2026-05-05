import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { nebula, dark, classic }

class ThemeManager extends ChangeNotifier {
  // Singleton instance
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  AppThemeMode _currentMode = AppThemeMode.nebula;
  AppThemeMode get currentMode => _currentMode;

  // Initialize from device storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme') ?? 'nebula';
    _currentMode = AppThemeMode.values.firstWhere(
      (e) => e.name == savedTheme, 
      orElse: () => AppThemeMode.nebula
    );
    notifyListeners();
  }

  // Change and save the theme
  Future<void> changeTheme(AppThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', mode.name);
  }

  // Helper colors that adapt based on the theme
  Color get primaryText => _currentMode == AppThemeMode.classic ? Colors.black87 : Colors.white;
  Color get secondaryText => _currentMode == AppThemeMode.classic ? Colors.grey[600]! : Colors.grey[400]!;
  Color get cardBg => _currentMode == AppThemeMode.classic ? Colors.white : Colors.black.withValues(alpha: 0.6);
  Color get accentGoldOrBlue => _currentMode == AppThemeMode.classic ? const Color(0xFF17A2B8) : const Color(0xFFD4AF37);
}