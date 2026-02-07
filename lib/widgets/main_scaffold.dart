// lib/widgets/main_scaffold.dart
// Shared scaffold with persistent bottom navigation bar using IndexedStack.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/widgets/liquid_glass_nav_bar.dart';

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

  /// Tab items for Liquid Glass nav bar
  /// Icons use SF Symbols - outline version (Swift adds .fill automatically for selected state)
  static const List<NavBarItem> _navItems = [
    NavBarItem(
      icon: 'house',
      flutterIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavBarItem(
      icon: 'person.2',
      flutterIcon: Icons.people_rounded,
      label: 'Members',
    ),
    NavBarItem(
      icon: 'calendar',
      flutterIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
    ),
    NavBarItem(
      icon: 'gearshape',
      flutterIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Use Liquid Glass nav bar on iOS, standard nav bar on Android
    final useNativeNavBar = Platform.isIOS;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      // Use extendBody for iOS to allow nav bar to float over content
      extendBody: useNativeNavBar,
      bottomNavigationBar: useNativeNavBar
          ? LiquidGlassNavBar(
              items: _navItems,
              selectedIndex: currentIndex,
              onItemSelected: onTabSelected,
              selectedColor: isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
              unselectedColor: isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected,
            )
          : _buildBottomNav(isDarkMode),
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
      icon: Semantics(
        label: label,
        button: true,
        selected: currentIndex == index,
        child: SvgPicture.asset(
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
      ),
      label: label,
      tooltip: label,
    );
  }
}
