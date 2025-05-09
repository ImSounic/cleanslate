// lib/features/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/navigation_provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final isDarkMode = ThemeUtils.isDarkMode(context);

    // List of screens for the bottom navigation
    final screens = [
      const HomeScreen(),
      const MembersScreen(),
      const ScheduleScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: navigationProvider.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationProvider.currentIndex,
          onTap: (index) => navigationProvider.setIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor:
              isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
          unselectedItemColor:
              isDarkMode
                  ? AppColors.navUnselectedDark
                  : AppColors.navUnselected,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor:
              isDarkMode ? AppColors.backgroundDark : AppColors.background,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/home.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  navigationProvider.currentIndex == 0
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/members.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  navigationProvider.currentIndex == 1
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Members',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/schedule.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  navigationProvider.currentIndex == 2
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/settings.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  navigationProvider.currentIndex == 3
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
