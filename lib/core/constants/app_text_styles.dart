// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontFamily: 'VarelaRound',
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontFamily: 'VarelaRound',
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontFamily: 'VarelaRound',
    color: AppColors.textSecondary,
  );

  // Secondary text
  static const TextStyle secondary = TextStyle(
    fontSize: 16,
    fontFamily: 'VarelaRound',
    color: AppColors.textSecondary,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontFamily: 'VarelaRound',
    fontWeight: FontWeight.w600,
  );
}
