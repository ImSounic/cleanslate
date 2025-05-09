// lib/core/utils/theme_utils.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

/// Utility class for theme-related operations
class ThemeUtils {
  /// Get current theme colors based on the theme mode
  static Color getTextPrimaryColor(BuildContext context) {
    // Change this to 'true' for getting live updates
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
  }

  static Color getBackgroundColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.backgroundDark
        : AppColors.background;
  }

  static Color getSurfaceColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  }

  static Color getBorderColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode ? AppColors.borderDark : AppColors.border;
  }

  static Color getBorderPrimaryColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.borderPrimaryDark
        : AppColors.borderPrimary;
  }

  static Color getDividerColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode ? AppColors.dividerDark : AppColors.divider;
  }

  static Color getIconColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.iconPrimaryDark
        : AppColors.iconPrimary;
  }

  static List<Color> getAuthGradient(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode
        ? AppColors.authGradientDark
        : AppColors.authGradient;
  }

  /// Get a color filter for SVGs based on current theme
  static ColorFilter getIconColorFilter(
    BuildContext context, {
    Color? customColor,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final color =
        customColor ??
        (themeProvider.isDarkMode
            ? AppColors.iconPrimaryDark
            : AppColors.iconPrimary);

    return ColorFilter.mode(color, BlendMode.srcIn);
  }

  /// Check if current theme is dark mode
  static bool isDarkMode(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return themeProvider.isDarkMode;
  }
}
