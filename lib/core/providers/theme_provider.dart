// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  // Key for storing theme preference
  static const String _themePreferenceKey = 'theme_preference';

  // Theme modes
  ThemeMode _themeMode = ThemeMode.light;

  // Constructor - loads saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;

  // Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    // Update status bar appearance based on theme
    _updateStatusBarAppearance();
    
    notifyListeners();

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDarkMode);
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    // Update status bar appearance based on theme
    _updateStatusBarAppearance();
    
    notifyListeners();

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDarkMode);
  }

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePreferenceKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Update status bar appearance based on loaded theme
    _updateStatusBarAppearance();
    
    notifyListeners();
  }
  
  // Update status bar appearance to match the current theme
  void _updateStatusBarAppearance() {
    if (isDarkMode) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark, // iOS: for dark status bar content
        statusBarIconBrightness: Brightness.light, // Android: for dark status bar content
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light, // iOS: for light status bar content
        statusBarIconBrightness: Brightness.dark, // Android: for light status bar content
      ));
    }
  }
}