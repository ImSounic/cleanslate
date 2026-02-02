// lib/core/widgets/feature_gate.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/features/subscription/screens/upgrade_screen.dart';

/// Shows an upgrade prompt bottom sheet when a subscription limit is reached.
class UpgradePromptSheet extends StatelessWidget {
  final String title;
  final String message;
  final String householdId;

  const UpgradePromptSheet({
    super.key,
    required this.title,
    required this.message,
    required this.householdId,
  });

  /// Convenience method to show the prompt as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required String householdId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(
        title: title,
        message: message,
        householdId: householdId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB800),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UpgradeScreen(householdId: householdId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Upgrade to Pro',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Not now
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not now',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
