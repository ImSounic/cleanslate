// lib/widgets/app_loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';

/// Consistent loading indicator used across the app.
///
/// [size] controls the diameter (default 24).
/// [strokeWidth] controls the line thickness (default 2.5).
/// [centered] wraps in a Center widget when true (default true).
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final bool centered;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.centered = true,
    this.color,
  });

  /// Small inline spinner (e.g. inside buttons).
  const AppLoadingIndicator.small({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.centered = false,
    this.color = AppColors.textLight,
  });

  /// Full-screen centered spinner.
  const AppLoadingIndicator.fullScreen({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.centered = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);
    final indicatorColor =
        color ?? (isDarkMode ? AppColors.primaryDark : AppColors.primary);

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: indicatorColor,
      ),
    );

    return centered ? Center(child: indicator) : indicator;
  }
}
