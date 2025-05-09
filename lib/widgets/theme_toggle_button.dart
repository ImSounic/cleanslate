// lib/widgets/theme_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set initial animation state based on theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (themeProvider.isDarkMode) {
        _animationController.value = 1.0;
      } else {
        _animationController.value = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Make sure animation is in the right state
    if (isDarkMode && _animationController.value == 0.0) {
      _animationController.value = 1.0;
    } else if (!isDarkMode && _animationController.value == 1.0) {
      _animationController.value = 0.0;
    }

    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
        if (isDarkMode) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      },
      child: Container(
        height: 32,
        width: 64,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                // Sliding circle background
                Transform.translate(
                  offset: Offset(_animation.value * 32, 0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Light mode icon
                Positioned(
                  left: 6,
                  top: 6,
                  child: Opacity(
                    opacity: 1 - _animation.value,
                    child: Icon(
                      Icons.light_mode,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // Dark mode icon
                Positioned(
                  right: 6,
                  top: 6,
                  child: Opacity(
                    opacity: _animation.value,
                    child: Icon(
                      Icons.dark_mode,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
