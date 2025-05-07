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
  static const Color background = Color(0xFFF4F3EE); // Main background
  static const Color surface = Color(0xFFFFFFFF); // Surface color for cards

  // Tab Colors
  static const Color tabInactive = Color(0xFFDEDDD8); // Unselected tab color

  // Text Colors
  static const Color textPrimary = Color(0xFF586AAF); // Primary text color
  static const Color textSecondary = Color(0xFF7896B6); // Secondary text color
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textDark = Color(0xFF1A1A1A); // Dark text

  // Border Colors
  static const Color border = Color(0xFFE5E5E5); // Light border
  static const Color borderPrimary = Color(0xFF586AAF); // Primary border

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Priority Colors (for chores)
  static const Color priorityHigh = Color(0xFFF44336);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityLow = Color(0xFF4CAF50);

  // Avatar Colors
  static const Color avatarAmber = Colors.amber;
  static const Color avatarGreen = Colors.green;
  static const Color avatarBrown = Colors.brown;
  static const Color avatarPurple = Colors.purple;

  // Additional UI Element Colors
  static const Color iconPrimary = Color(0xFF586AAF);
  static const Color divider = Color(0xFFE5E5E5);

  // Navigation Colors
  static const Color navSelected = Color(0xFF586AAF);
  static const Color navUnselected = Colors.grey;

  // Authentication Gradient
  static const List<Color> authGradient = [
    Color(0xFF0D2E52), // Dark blue
    Color(0xFF2185D0), // Light blue
  ];

  // Helper methods for opacity variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Common opacity values
  static Color get primaryLight50 => primary.withOpacity(0.5);
  static Color get primaryLight30 => primary.withOpacity(0.3);
}
