// lib/features/home/screens/home_screen.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/features/chores/screens/add_chore_screen.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/features/notifications/screens/notifications_screen.dart';
import 'package:cleanslate/data/repositories/notification_repository.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _choreRepository = ChoreRepository();
  final _notificationRepository = NotificationRepository();
  String _userName = '';
  List<Map<String, dynamic>> _myChores = [];
  List<Map<String, dynamic>> _completedChores = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  int _unreadNotificationsCount = 0;
  int _selectedNavIndex = 0;
  bool _hasNotifications = false;
  bool _isDarkMode = false;

  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  // Updated tab titles to include Completed
  final List<String> _tabTitles = [
    'My Tasks',
    'In-progress',
    'Assigned to',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChores();
    _loadNotificationCount();

    // Set up periodic notification checks
    _setupNotificationRefresh();

    // Initialize animation controller
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
    );
  }

  void _setupNotificationRefresh() {
    // Refresh notification count every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadNotificationCount();
        _setupNotificationRefresh();
      }
    });
  }

  @override
  void dispose() {
    _toggleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _supabaseService.currentUser;
    if (user != null) {
      final userData = user.userMetadata;
      if (userData != null && userData.containsKey('full_name')) {
        setState(() {
          _userName = userData['full_name'] as String;
        });
      } else {
        setState(() {
          _userName = user.email?.split('@').first ?? 'User';
        });
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _notificationRepository.getUnreadNotificationsCount();
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
          _hasNotifications = count > 0;
        });
      }
    } catch (e) {
      // Silently handle error
      print('Error loading notification count: $e');
    }
  }

  Future<void> _loadChores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chores = await _choreRepository.getMyChores();

      // Separate completed and pending chores
      final completed = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];

      for (final chore in chores) {
        if (chore['status'] == 'completed') {
          completed.add(chore);
        } else {
          pending.add(chore);
        }
      }

      setState(() {
        _myChores = pending;
        _completedChores = completed;
      });
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading chores: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User profile section
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Switzer',
                  ),
                ),
                Text(
                  _supabaseService.currentUser?.email ?? 'sounic@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'VarelaRound',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Menu options
                _buildProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'View Profile',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to profile screen
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.home_outlined,
                  title: 'Household Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to household settings
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  isDarkModeOption: true,
                ),
                _buildProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to help screen
                  },
                ),
                const Divider(),
                _buildProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    bool isDarkModeOption = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'VarelaRound',
        ),
      ),
      trailing:
          isDarkModeOption
              ? Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                    if (_isDarkMode) {
                      _toggleController.forward();
                    } else {
                      _toggleController.reverse();
                    }
                  });
                  Navigator.pop(context);
                },
                activeColor: AppColors.primary,
              )
              : null,
      dense: true,
      onTap: isDarkModeOption ? null : onTap,
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _completeChore(String assignmentId) async {
    try {
      await _choreRepository.completeChore(assignmentId);
      // Refresh chores list
      _loadChores();
      // Also refresh notification count since completing a chore
      // might generate notifications
      _loadNotificationCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing chore: $e')));
      }
    }
  }

  // Method to uncomplete a chore
  Future<void> _uncompleteChore(String assignmentId) async {
    try {
      // Use the repository method instead of direct client access
      await _choreRepository.uncompleteChore(assignmentId);

      // Refresh chores list
      _loadChores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uncompleting chore: $e')));
      }
    }
  }

  // Method to show task details overlay
  void _showTaskDetailsOverlay(
    Map<String, dynamic> chore,
    Map<String, dynamic> assignment,
  ) {
    // Parse the description to look for to-do items
    final description = chore['description'] as String? ?? '';
    List<Map<String, dynamic>> todoItems = [];

    // Extract to-do items from description if they follow the format "- [ ] Task" or "- [x] Task"
    final todoRegex = RegExp(r'- \[([ x])\] (.+)');
    final matches = todoRegex.allMatches(description);

    for (final match in matches) {
      final isCompleted = match.group(1) == 'x';
      final taskText = match.group(2) ?? '';
      todoItems.add({'text': taskText, 'completed': isCompleted});
    }

    // Clean description by removing to-do items
    String cleanDescription = description;
    if (todoItems.isNotEmpty) {
      // If there are to-do items, remove them from the description
      final todoStartIndex = description.indexOf('To-do items:');
      if (todoStartIndex != -1) {
        cleanDescription = description.substring(0, todoStartIndex).trim();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Details header
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/task_details.svg',
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Task Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Switzer',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task title and description
                Text(
                  chore['name'] ?? 'Untitled Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'VarelaRound',
                  ),
                ),

                if (cleanDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cleanDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ],

                // To-do items if any
                if (todoItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...todoItems.map(
                    (todo) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: todo['completed'],
                              onChanged: null, // Read-only in overlay
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todo['text'],
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'VarelaRound',
                                color: Colors.black87,
                                decoration:
                                    todo['completed']
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // User profile picture in bottom right
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.avatarAmber,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontFamily: 'VarelaRound',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract first name from full name
    final firstName = _userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with icons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Theme toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                        if (_isDarkMode) {
                          _toggleController.forward();
                        } else {
                          _toggleController.reverse();
                        }
                      });
                    },
                    child: Container(
                      height: 32,
                      width: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: AnimatedBuilder(
                        animation: _toggleAnimation,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Sliding circle background
                              Transform.translate(
                                offset: Offset(_toggleAnimation.value * 32, 0),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Light mode icon
                              Positioned(
                                left: 6,
                                top: 6,
                                child: Opacity(
                                  opacity: 1 - _toggleAnimation.value,
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
                                  opacity: _toggleAnimation.value,
                                  child: Icon(
                                    Icons.dark_mode,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notifications with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Navigate to notifications screen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                          // Refresh notification count after returning
                          _loadNotificationCount();
                        },
                        child: SvgPicture.asset(
                          _hasNotifications
                              ? 'assets/images/icons/red_bell.svg'
                              : 'assets/images/icons/bell.svg',
                          height: 24,
                          width: 24,
                          colorFilter:
                              _hasNotifications
                                  ? null
                                  : ColorFilter.mode(
                                    AppColors.iconPrimary,
                                    BlendMode.srcIn,
                                  ),
                        ),
                      ),
                      // Notification badge
                      if (_unreadNotificationsCount > 0)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationsCount > 9
                                  ? '9+'
                                  : _unreadNotificationsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Profile
                  GestureDetector(
                    onTap: _showProfileMenu,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textLight,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Greeting below the top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello $firstName!',
                    style: const TextStyle(
                      fontSize: 48,
                      fontFamily: 'Switzer',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Have a nice day.',
                    style: TextStyle(
                      fontSize: 23,
                      fontFamily: 'VarelaRound',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab buttons - Made horizontally scrollable
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabTitles.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTabButton(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Chore list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildChoreContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: AppColors.textLight),
        onPressed: () async {
          // Navigate to the add chore screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChoreScreen()),
          );

          // If a chore was added successfully, refresh the list
          if (result == true) {
            _loadChores();
            // Adding a chore might create notifications
            _loadNotificationCount();
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) async {
            // Handle navigation based on selected index
            if (index == 1) {
              // Members tab
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MembersScreen()),
              );
              // Reset the selected index to home after returning from members screen
              setState(() {
                _selectedNavIndex = 0;
              });
              // Refresh notification count after returning
              _loadNotificationCount();
            } else if (index == 2) {
              // Schedule tab - Add this section
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScheduleScreen()),
              );
              // Reset the selected index to home after returning from schedule screen
              setState(() {
                _selectedNavIndex = 0;
              });
              // Refresh notification count after returning
              _loadNotificationCount();
            } else if (index == 3) {
              // Settings tab
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // Reset the selected index to home after returning from settings screen
              setState(() {
                _selectedNavIndex = 0;
              });
              // Refresh notification count after returning
              _loadNotificationCount();
            } else {
              setState(() {
                _selectedNavIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.navSelected,
          unselectedItemColor: AppColors.navUnselected,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/home.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  _selectedNavIndex == 0
                      ? AppColors.navSelected
                      : AppColors.navUnselected,
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
                  _selectedNavIndex == 1
                      ? AppColors.navSelected
                      : AppColors.navUnselected,
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
                  _selectedNavIndex == 2
                      ? AppColors.navSelected
                      : AppColors.navUnselected,
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
                  _selectedNavIndex == 3
                      ? AppColors.navSelected
                      : AppColors.navUnselected,
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

  // Method to show appropriate content based on selected tab
  Widget _buildChoreContent() {
    // Show appropriate content based on selected tab
    switch (_selectedTabIndex) {
      case 0: // My Tasks
        return _myChores.isEmpty
            ? _buildEmptyState()
            : _buildChoresList(_myChores);
      case 3: // Completed
        return _completedChores.isEmpty
            ? _buildEmptyStateWithMessage(
              'No completed chores',
              'Complete your tasks to see them here',
            )
            : _buildChoresList(_completedChores);
      default: // Other tabs - placeholder for now
        return _buildEmptyStateWithMessage(
          'Coming Soon',
          'This tab is under development',
        );
    }
  }

  Widget _buildTabButton(int index) {
    final isSelected = _selectedTabIndex == index;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected ? AppColors.borderPrimary : AppColors.tabInactive,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        foregroundColor: isSelected ? AppColors.primary : AppColors.tabInactive,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        _tabTitles[index],
        style: const TextStyle(fontSize: 14, fontFamily: 'VarelaRound'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No chores assigned to you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add chores to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'VarelaRound',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChoreScreen()),
              );
              if (result == true) {
                _loadChores();
                _loadNotificationCount();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Chore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithMessage(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'VarelaRound',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChoresList(List<Map<String, dynamic>> chores) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadChores();
        await _loadNotificationCount();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chores.length,
        itemBuilder: (context, index) {
          final choreAssignment = chores[index];
          final chore = choreAssignment['chores'] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChoreCard(choreAssignment, chore),
          );
        },
      ),
    );
  }

  Widget _buildChoreCard(
    Map<String, dynamic> assignment,
    Map<String, dynamic> chore,
  ) {
    // Determine priority color
    Color priorityColor;
    switch ((assignment['priority'] ?? 'medium').toLowerCase()) {
      case 'high':
        priorityColor = AppColors.priorityHigh;
        break;
      case 'medium':
        priorityColor = AppColors.priorityMedium;
        break;
      case 'low':
        priorityColor = AppColors.priorityLow;
        break;
      default:
        priorityColor = AppColors.priorityMedium;
    }

    // Format due date
    String dueDate = 'No date';
    if (assignment['due_date'] != null) {
      final date = DateTime.parse(assignment['due_date']);
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        dueDate = 'Today';
      } else if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        dueDate = 'Tomorrow';
      } else {
        dueDate = DateFormat('MMM d, yyyy').format(date);
      }
    }

    // Determine completion status
    final isCompleted = assignment['status'] == 'completed';

    // Get assignee first name only
    final assigneeFullName = _userName;
    final assigneeFirstName = assigneeFullName.split(' ').first;
    final assigneeInitial =
        assigneeFullName.isNotEmpty ? assigneeFullName[0].toUpperCase() : 'U';

    // Check if chore has description
    final hasDescription =
        chore['description'] != null &&
        chore['description'].toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      // Reduced height for the card
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN - Completion circle for the entire height
          GestureDetector(
            onTap: () {
              if (isCompleted) {
                // If task is completed, allow unchecking
                _uncompleteChore(assignment['id']);
              } else {
                // If task is pending, mark as complete
                _completeChore(assignment['id']);
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isCompleted ? AppColors.primary : AppColors.borderPrimary,
                  width: 2,
                ),
                color: isCompleted ? AppColors.primary : Colors.transparent,
              ),
              child:
                  isCompleted
                      ? Icon(Icons.check, color: AppColors.textLight, size: 16)
                      : null,
            ),
          ),

          const SizedBox(width: 16),

          // MIDDLE/MAIN CONTENT - Chore details in column layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW - Title only (description icon moved down)
                Text(
                  chore['name'] ?? 'Unnamed Chore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Switzer',
                    color: AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // ASSIGNEE ROW - Including first name and description icon
                Row(
                  children: [
                    Text(
                      'Assignee: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.avatarAmber,
                      child: Text(
                        assigneeInitial,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          fontFamily: 'VarelaRound',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Only show first name
                    Text(
                      assigneeFirstName,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Description icon moved here after assignee first name
                    if (hasDescription)
                      GestureDetector(
                        onTap: () {
                          // Show the task details overlay when icon is tapped
                          _showTaskDetailsOverlay(chore, assignment);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SvgPicture.asset(
                            'assets/images/icons/scroll_description.svg',
                            height: 14,
                            width: 14,
                            colorFilter: ColorFilter.mode(
                              AppColors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Spacer to push elements to their positions
                const Spacer(),
              ],
            ),
          ),

          // RIGHT COLUMN - Priority, options, and due date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TOP RIGHT ROW - Priority flag and three dots in a row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flag icon
                  SvgPicture.asset(
                    'assets/images/icons/flag.svg',
                    height: 14,
                    width: 14,
                    colorFilter: ColorFilter.mode(
                      priorityColor,
                      BlendMode.srcIn,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Priority text
                  Text(
                    _capitalize(
                      (assignment['priority'] ?? 'Medium').toString(),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color: priorityColor,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Three dots menu on the same row
                  GestureDetector(
                    onTap: () {
                      _showChoreOptions(assignment, chore);
                    },
                    child: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // BOTTOM RIGHT - Due date
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/icons/clock.svg',
                    height: 12,
                    width: 12,
                    colorFilter: ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChoreOptions(
    Map<String, dynamic> assignment,
    Map<String, dynamic> chore,
  ) {
    final isCompleted = assignment['status'] == 'completed';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit Chore'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit chore screen
                },
              ),
              if (!isCompleted)
                ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.primary),
                  title: const Text('Mark as Complete'),
                  onTap: () {
                    Navigator.pop(context);
                    _completeChore(assignment['id']);
                  },
                ),
              if (isCompleted)
                ListTile(
                  leading: Icon(
                    Icons.radio_button_unchecked,
                    color: AppColors.primary,
                  ),
                  title: const Text('Mark as Pending'),
                  onTap: () {
                    Navigator.pop(context);
                    _uncompleteChore(assignment['id']);
                  },
                ),
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: const Text('Reassign Chore'),
                onTap: () {
                  Navigator.pop(context);
                  // Show reassign dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Chore',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show delete confirmation
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to capitalize strings
  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
