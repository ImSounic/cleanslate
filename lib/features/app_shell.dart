// lib/features/app_shell.dart
// App shell that holds all main tab screens in an IndexedStack,
// preserving state across tab switches.

import 'package:flutter/material.dart';
import 'package:cleanslate/widgets/main_scaffold.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/features/chores/screens/add_chore_screen.dart';
import 'package:cleanslate/core/utils/error_handler.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class AppShell extends StatefulWidget {
  /// Optional initial tab index (default 0 = Home).
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  // GlobalKeys to access child screen states for refresh after adding chores
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ScheduleScreenState> _scheduleKey = GlobalKey<ScheduleScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Build FAB based on current tab
  Widget? _buildFAB() {
    // Show Add Chore FAB on Home (0) and Schedule (2) tabs
    if (_currentIndex == 0 || _currentIndex == 2) {
      return FloatingActionButton(
        heroTag: 'add_chore_fab',
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: AppColors.textLight),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChoreScreen()),
          );
          if (result == true) {
            // Refresh both screens since chores may appear in both
            _homeKey.currentState?.refreshChores();
            _scheduleKey.currentState?.refreshChores();
          }
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      floatingActionButton: _buildFAB(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ErrorBoundary(child: HomeScreen(key: _homeKey)),
          const ErrorBoundary(child: MembersScreen()),
          ErrorBoundary(child: ScheduleScreen(key: _scheduleKey)),
          const ErrorBoundary(child: SettingsScreen()),
        ],
      ),
    );
  }
}
