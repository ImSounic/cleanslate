// lib/features/app_shell.dart
// App shell that holds all main tab screens in an IndexedStack,
// preserving state across tab switches.

import 'package:flutter/material.dart';
import 'package:cleanslate/widgets/main_scaffold.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/core/utils/error_handler.dart';

class AppShell extends StatefulWidget {
  /// Optional initial tab index (default 0 = Home).
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  // Keep all tab screens alive using GlobalKeys to preserve state.
  // Each screen is wrapped in an ErrorBoundary to catch rendering errors
  // gracefully instead of crashing the entire app.
  final List<Widget> _screens = const [
    ErrorBoundary(child: HomeScreen()),
    ErrorBoundary(child: MembersScreen()),
    ErrorBoundary(child: ScheduleScreen()),
    ErrorBoundary(child: SettingsScreen()),
  ];

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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
