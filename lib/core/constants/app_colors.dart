// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(
    0xFF586AAF,
  ); // Main blue color for text and borders
  static const Color primaryLight = Color(
    0xFF7896B6,
  ); // Light blue for secondary text

  // Background Colors
  static const Color background = Color(
    0xFFF4F3EE,
  ); // Main background (Light mode)
  static const Color surface = Color(
    0xFFFFFFFF,
  ); // Surface color for cards (Light mode)

  // Dark mode Colors
  static const Color backgroundDark = Color(0xFF151A2C); // Dark mode background
  static const Color surfaceDark = Color(
    0xFF1E2642,
  ); // Dark mode surface color for cards
  static const Color primaryDark = Color(
    0xFF586AAF,
  ); // Same primary color for dark mode
  static const Color primaryLightDark = Color(
    0xFF7896B6,
  ); // Same primary light for dark mode

  // Tab Colors
  static const Color tabInactive = Color(0xFFDEDDD8); // Unselected tab color
  static const Color tabInactiveDark = Color(
    0xFF3A4060,
  ); // Dark mode unselected tab color

  // Text Colors
  static const Color textPrimary = Color(
    0xFF586AAF,
  ); // Primary text color (Light mode)
  static const Color textSecondary = Color(
    0xFF7896B6,
  ); // Secondary text color (Light mode)
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textDark = Color(0xFF1A1A1A); // Dark text

  // Dark mode text colors
  static const Color textPrimaryDark = Color(
    0xFFFFFFFF,
  ); // Primary text color (Dark mode)
  static const Color textSecondaryDark = Color(
    0xFFB4BCD0,
  ); // Secondary text color (Dark mode)

  // Border Colors
  static const Color border = Color(0xFFE5E5E5); // Light border
  static const Color borderPrimary = Color(0xFF586AAF); // Primary border

  // Dark mode border colors
  static const Color borderDark = Color(0xFF2A3050); // Dark mode border
  static const Color borderPrimaryDark = Color(
    0xFF586AAF,
  ); // Dark mode primary border

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Priority Colors (for chores)
  static const Color priorityHigh = Color(0xFFF44336);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityLow = Color(0xFF4CAF50);

  // Avatar Colors — deterministic palette based on userId hash
  static const List<Color> avatarPalette = [
    Color(0xFFE57373), // red
    Color(0xFFFF8A65), // deep orange
    Color(0xFFFFB74D), // orange
    Color(0xFFFFD54F), // amber
    Color(0xFF81C784), // green
    Color(0xFF4DB6AC), // teal
    Color(0xFF4FC3F7), // light blue
    Color(0xFF7986CB), // indigo
    Color(0xFFBA68C8), // purple
    Color(0xFFF06292), // pink
    Color(0xFFA1887F), // brown
    Color(0xFF90A4AE), // blue grey
  ];

  /// Returns a consistent avatar color for a given userId.
  static Color avatarColorFor(String userId) {
    final hash = userId.hashCode.abs();
    return avatarPalette[hash % avatarPalette.length];
  }

  // Legacy — kept for backward compatibility but prefer avatarColorFor()
  static const Color avatarAmber = Colors.amber;
  static const Color avatarGreen = Colors.green;
  static const Color avatarBrown = Colors.brown;
  static const Color avatarPurple = Colors.purple;

  // Additional UI Element Colors
  static const Color iconPrimary = Color(0xFF586AAF);
  static const Color iconPrimaryDark = Color(0xFFFFFFFF); // Dark mode icons
  static const Color divider = Color(0xFFE5E5E5);
  static const Color dividerDark = Color(0xFF2A3050); // Dark mode divider

  // Navigation Colors
  static const Color navSelected = Color(0xFF586AAF);
  static const Color navUnselected = Colors.grey;

  // Dark mode navigation colors
  static const Color navSelectedDark = Color(0xFFFFFFFF);
  static const Color navUnselectedDark = Color(0xFF6D7A9F);

  // Authentication Gradient
  static const List<Color> authGradient = [
    Color(0xFF0D2E52), // Dark blue
    Color(0xFF2185D0), // Light blue
  ];

  // Dark mode auth gradient
  static const List<Color> authGradientDark = [
    Color(0xFF151A2C), // Darker blue
    Color(0xFF1E2642), // Dark purple-blue
  ];

  // Helper methods for opacity variations
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Common opacity values
  static Color get primaryLight50 => primary.withValues(alpha: 0.5);
  static Color get primaryLight30 => primary.withValues(alpha: 0.3);
}
