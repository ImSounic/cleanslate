// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.navSelected,
      unselectedItemColor: AppColors.navUnselected,
      backgroundColor: AppColors.surface,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.tabInactive),
        foregroundColor: AppColors.tabInactive,
      ),
    ),
  );
}
