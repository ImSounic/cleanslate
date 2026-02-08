// lib/features/onboarding/screens/setup_onboarding_screen.dart
// Post-signup onboarding that guides users to set up chore preferences
// Shown after first login to help with the auto-assignment algorithm

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/features/app_shell.dart';
import 'package:cleanslate/features/profile/screens/chore_preferences_screen.dart';

/// Data model for setup onboarding pages
class _SetupPage {
  final IconData icon;
  final String title;
  final String description;
  final bool hasAction;
  final String? actionLabel;

  const _SetupPage({
    required this.icon,
    required this.title,
    required this.description,
    this.hasAction = false,
    this.actionLabel,
  });
}

class SetupOnboardingScreen extends StatefulWidget {
  const SetupOnboardingScreen({super.key});

  @override
  State<SetupOnboardingScreen> createState() => _SetupOnboardingScreenState();
}

class _SetupOnboardingScreenState extends State<SetupOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_SetupPage> _pages = [
    _SetupPage(
      icon: Icons.waving_hand_rounded,
      title: 'Welcome!',
      description:
          'Let\'s set up your account so the chore assignment algorithm works best for you.',
    ),
    _SetupPage(
      icon: Icons.favorite_rounded,
      title: 'Your Preferences Matter',
      description:
          'Tell us which chores you prefer and your availability. This helps us assign chores fairly.',
      hasAction: true,
      actionLabel: 'Set Up Preferences',
    ),
    _SetupPage(
      icon: Icons.home_rounded,
      title: 'Create or Join',
      description:
          'Create a new household and invite your flatmates, or join an existing one with a code.',
    ),
    _SetupPage(
      icon: Icons.check_circle_rounded,
      title: 'You\'re All Set!',
      description:
          'Once everyone joins, tap the "Assign Chores" button on the home screen to get started.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeSetupOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetupOnboarding();
    }
  }

  Future<void> _openPreferences() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChorePreferencesScreen()),
    );
    // After returning from preferences, move to next page
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDarkMode(context);
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeSetupOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: textSecondary,
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ),
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(
                    page: page,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index, isDark),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next button (unless page has special action)
                  if (!_pages[_currentPage].hasAction)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required _SetupPage page,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with circular background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),

          // Action button if present
          if (page.hasAction && page.actionLabel != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openPreferences,
                icon: const Icon(Icons.tune),
                label: Text(
                  page.actionLabel!,
                  style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip for now',
                style: TextStyle(color: textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : (isDark
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
