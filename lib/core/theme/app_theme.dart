// lib/core/theme/app_theme.dart
// ignore_for_file: deprecated_member_use

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
      backgroundColor: AppColors.background,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.tabInactive),
        foregroundColor: AppColors.tabInactive,
      ),
    ),
    fontFamily: 'VarelaRound',
  );

  // New dark theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.primaryLightDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: AppColors.textLight,
      onBackground: AppColors.textPrimaryDark,
      onSurface: AppColors.textPrimaryDark,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.navSelectedDark,
      unselectedItemColor: AppColors.navUnselectedDark,
      backgroundColor: AppColors.backgroundDark,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.tabInactiveDark),
        foregroundColor: AppColors.tabInactiveDark,
      ),
    ),
    dividerColor: AppColors.dividerDark,
    dialogBackgroundColor: AppColors.surfaceDark,
    cardColor: AppColors.surfaceDark,
    textTheme: TextTheme(
      // Apply the text colors for dark theme
      bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
      bodyMedium: TextStyle(color: AppColors.textPrimaryDark),
      bodySmall: TextStyle(color: AppColors.textSecondaryDark),
      titleLarge: TextStyle(color: AppColors.textPrimaryDark),
      titleMedium: TextStyle(color: AppColors.textPrimaryDark),
      titleSmall: TextStyle(color: AppColors.textPrimaryDark),
    ),
    fontFamily: 'VarelaRound',
  );
}
