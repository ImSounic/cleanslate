// lib/widgets/main_scaffold.dart
// Shared scaffold with persistent bottom navigation bar using IndexedStack.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';

class MainScaffold extends StatelessWidget {
  /// The current tab index (0=Home, 1=Members, 2=Schedule, 3=Settings).
  final int currentIndex;

  /// Callback when a bottom nav tab is tapped.
  final ValueChanged<int> onTabSelected;

  /// The body content widget (typically an IndexedStack).
  final Widget body;

  /// Optional FloatingActionButton.
  final Widget? floatingActionButton;

  /// Optional FloatingActionButton location.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: _buildBottomNav(isDarkMode),
    );
  }

  Widget _buildBottomNav(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
        unselectedItemColor:
            isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        items: [
          _buildNavItem(
            'assets/images/icons/home.svg',
            'Home',
            0,
            isDarkMode,
          ),
          _buildNavItem(
            'assets/images/icons/members.svg',
            'Members',
            1,
            isDarkMode,
          ),
          _buildNavItem(
            'assets/images/icons/schedule.svg',
            'Calendar',
            2,
            isDarkMode,
          ),
          _buildNavItem(
            'assets/images/icons/settings.svg',
            'Settings',
            3,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String svgPath,
    String label,
    int index,
    bool isDarkMode,
  ) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        svgPath,
        height: 24,
        width: 24,
        colorFilter: ColorFilter.mode(
          currentIndex == index
              ? (isDarkMode
                  ? AppColors.navSelectedDark
                  : AppColors.navSelected)
              : (isDarkMode
                  ? AppColors.navUnselectedDark
                  : AppColors.navUnselected),
          BlendMode.srcIn,
        ),
      ),
      label: label,
    );
  }
}
