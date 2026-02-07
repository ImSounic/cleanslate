// lib/widgets/main_scaffold.dart
// Shared scaffold with persistent bottom navigation bar using IndexedStack.

import 'package:flutter/material.dart';
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
  static const List<NavBarItem> _navItems = [
    NavBarItem(
      icon: 'house.fill',
      flutterIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavBarItem(
      icon: 'person.2.fill',
      flutterIcon: Icons.people_rounded,
      label: 'Members',
    ),
    NavBarItem(
      icon: 'calendar',
      flutterIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
    ),
    NavBarItem(
      icon: 'gearshape.fill',
      flutterIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

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
      // Extend body to allow glass nav bar to float over content
      extendBody: true,
      bottomNavigationBar: LiquidGlassNavBar(
        items: _navItems,
        selectedIndex: currentIndex,
        onItemSelected: onTabSelected,
        selectedColor: isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
        unselectedColor: isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected,
      ),
    );
  }

}
