// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/features/chores/screens/add_chore_screen.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _choreRepository = ChoreRepository();
  String _userName = '';
  List<Map<String, dynamic>> _myChores = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  int _selectedNavIndex = 0;
  bool _hasNotifications = false;
  bool _isDarkMode = false;

  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  final List<String> _tabTitles = ['My Tasks', 'In-progress', 'Assigned to'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChores();

    // Initialize animation controller
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
    );
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

  Future<void> _loadChores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chores = await _choreRepository.getMyChores();
      setState(() {
        _myChores = chores;
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing chore: $e')));
      }
    }
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
                  // Notifications
                  GestureDetector(
                    onTap: () {
                      // Show notifications
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
                      : _myChores.isEmpty
                      ? _buildEmptyState()
                      : _buildChoresList(),
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
            color: AppColors.textSecondary.withOpacity(0.5),
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

  Widget _buildChoresList() {
    return RefreshIndicator(
      onRefresh: _loadChores,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myChores.length,
        itemBuilder: (context, index) {
          final choreAssignment = _myChores[index];
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

    // Get assignee full name and initial
    final assigneeFullName = _userName;
    final assigneeInitial =
        assigneeFullName.isNotEmpty ? assigneeFullName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row with chore name, completion circle, and priority
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion circle - make it interactive
              GestureDetector(
                onTap: () {
                  if (!isCompleted) {
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
                          isCompleted
                              ? AppColors.primary
                              : AppColors.borderPrimary,
                      width: 2,
                    ),
                    color: isCompleted ? AppColors.primary : Colors.transparent,
                  ),
                  child:
                      isCompleted
                          ? Icon(
                            Icons.check,
                            color: AppColors.textLight,
                            size: 16,
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 16),

              // Chore name
              Expanded(
                child: Text(
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
              ),

              // Priority label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Text(
                    (assignment['priority'] ?? 'Medium')
                        .toString()
                        .capitalize(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color: priorityColor,
                    ),
                  ),
                ],
              ),

              // More options
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    // Show chore options
                    _showChoreOptions(assignment, chore);
                  },
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8), // Space between rows
          // Bottom row with assignee and due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Assignee info
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
                    backgroundColor: AppColors.avatarAmber, // Default color
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
                  // Show full name now since we have more space
                  Flexible(
                    child: Text(
                      assigneeFullName,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show description icon only if there is a description
                  if (chore['description'] != null &&
                      chore['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SvgPicture.asset(
                        'assets/images/icons/scroll_description.svg',
                        height: 12,
                        width: 12,
                        colorFilter: ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                ],
              ),

              // Due date
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
              ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.primary),
                title: const Text('Mark as Complete'),
                onTap: () {
                  Navigator.pop(context);
                  _completeChore(assignment['id']);
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
}

// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
