// lib/features/home/screens/home_screen.dart
// Updated with proper user profile picture in top right and in profile menu

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/features/chores/screens/add_chore_screen.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/features/notifications/screens/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _choreRepository = ChoreRepository();
  String _userName = '';
  String? _profileImageUrl; // Added property for profile image URL
  List<Map<String, dynamic>> _myChores = [];
  List<Map<String, dynamic>> _completedChores =
      []; // Added completed chores list
  bool _isLoading = true;
  int _selectedTabIndex = 0;

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

    // Initialize animation controller
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
    );

    // Set initial animation state based on current theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (themeProvider.isDarkMode) {
        _toggleController.value = 1.0;
      } else {
        _toggleController.value = 0.0;
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
      setState(() {
        if (userData != null && userData.containsKey('full_name')) {
          _userName = userData['full_name'] as String;
        } else {
          // If full_name is not available, use email or a default value
          _userName = user.email?.split('@').first ?? 'User';
        }
        // Add profile image URL loading
        _profileImageUrl = userData?['profile_image_url'];
      });
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
    // Get the current theme state
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User profile section with profile image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child:
                      _profileImageUrl == null
                          ? Icon(Icons.person, color: Colors.white, size: 36)
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _supabaseService.currentUser?.email ?? 'email@example.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
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
    // Get the current theme provider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              isDestructive
                  ? Colors.red
                  : isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'VarelaRound',
        ),
      ),
      trailing:
          isDarkModeOption
              ? Switch(
                value: isDarkMode,
                onChanged: (value) {
                  // Toggle the theme using the provider
                  themeProvider.toggleTheme();

                  // Update the animation based on the new theme
                  if (value) {
                    _toggleController.forward();
                  } else {
                    _toggleController.reverse();
                  }

                  Navigator.pop(context);
                },
                activeThumbColor: AppColors.primary,
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

  // Updated: Method to delete a chore by its ID, not just the assignment
  Future<void> _deleteChore(String choreId, String assignmentId) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // First delete the assignment
      await _choreRepository.deleteChoreAssignment(assignmentId);

      // Then delete the chore from the chores table
      await _choreRepository.deleteChore(choreId);

      // Refresh chores list after deletion
      await _loadChores();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chore deleted successfully')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting chore: $e')));
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to show task details overlay
  void _showTaskDetailsOverlay(
    Map<String, dynamic> chore,
    Map<String, dynamic> assignment,
  ) {
    // Get the current theme state
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

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
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
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
                      style: AppTextStyles.dialogTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task title and description
                Text(
                  chore['name'] ?? 'Untitled Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode ? AppColors.textPrimaryDark : Colors.black87,
                    fontFamily: 'VarelaRound',
                  ),
                ),

                if (cleanDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cleanDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : Colors.black54,
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
                                color:
                                    isDarkMode
                                        ? AppColors.textPrimaryDark
                                        : Colors.black87,
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
                    child:
                        _profileImageUrl != null
                            ? CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(_profileImageUrl!),
                            )
                            : CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.avatarAmber,
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'U',
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

    // Access the theme provider to check if dark mode is enabled
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Ensure the animation state matches the theme
    if (isDarkMode && _toggleController.value == 0.0) {
      _toggleController.value = 1.0;
    } else if (!isDarkMode && _toggleController.value == 1.0) {
      _toggleController.value = 0.0;
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with icons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Theme toggle
                  GestureDetector(
                    onTap: () {
                      // Toggle theme using the provider
                      themeProvider.toggleTheme();

                      // Animation will update automatically based on didUpdateWidget
                    },
                    child: Container(
                      height: 32,
                      width: 64,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary,
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
                                    color:
                                        isDarkMode
                                            ? AppColors.surfaceDark
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
                                    color:
                                        isDarkMode
                                            ? AppColors.textLight
                                            : AppColors.primary,
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
                  // Notifications with Consumer
                  Consumer<NotificationService>(
                    builder: (context, service, child) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              service.hasNotifications
                                  ? 'assets/images/icons/red_bell.svg'
                                  : 'assets/images/icons/bell.svg',
                              height: 24,
                              width: 24,
                              colorFilter:
                                  service.hasNotifications
                                      ? null
                                      : ColorFilter.mode(
                                        isDarkMode
                                            ? AppColors.iconPrimaryDark
                                            : AppColors.iconPrimary,
                                        BlendMode.srcIn,
                                      ),
                            ),
                            if (service.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      service.unreadCount > 9
                                          ? '9+'
                                          : service.unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Profile - Updated to show user profile picture
                  GestureDetector(
                    onTap: _showProfileMenu,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
                          width: 1,
                        ),
                      ),
                      child:
                          _profileImageUrl != null
                              ? ClipOval(
                                child: Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 32,
                                  height: 32,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                        color:
                                            isDarkMode
                                                ? AppColors.primaryDark
                                                : AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: 18,
                                    );
                                  },
                                ),
                              )
                              : Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 18,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          // Greeting below the top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello $firstName!',
                    style: AppTextStyles.greeting.copyWith(
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Have a nice day.',
                    style: AppTextStyles.subtitle.copyWith(
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
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
                    child: _buildTabButton(index, isDarkMode),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Chore list
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color:
                              isDarkMode
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
                        ),
                      )
                      : _buildChoreContent(isDarkMode),
            ),
          ],
        ),
      );
  }

  /// Builds the FAB for adding chores — used by AppShell.
  Widget buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      shape: const CircleBorder(),
      child: Icon(Icons.add, color: AppColors.textLight),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddChoreScreen()),
        );
        if (result == true) {
          _loadChores();
        }
      },
    );
  }

  // Method to show appropriate content based on selected tab
  Widget _buildChoreContent(bool isDarkMode) {
    // Show appropriate content based on selected tab
    switch (_selectedTabIndex) {
      case 0: // My Tasks
        return _myChores.isEmpty
            ? _buildEmptyState(isDarkMode)
            : _buildChoresList(_myChores, isDarkMode);
      case 3: // Completed
        return _completedChores.isEmpty
            ? _buildEmptyStateWithMessage(
              'No completed chores',
              'Complete your tasks to see them here',
              isDarkMode,
            )
            : _buildChoresList(_completedChores, isDarkMode);
      default: // Other tabs - placeholder for now
        return _buildEmptyStateWithMessage(
          'Coming Soon',
          'This tab is under development',
          isDarkMode,
        );
    }
  }

  Widget _buildTabButton(int index, bool isDarkMode) {
    final isSelected = _selectedTabIndex == index;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color:
              isSelected
                  ? AppColors.borderPrimary
                  : isDarkMode
                  ? AppColors.tabInactiveDark
                  : AppColors.tabInactive,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        foregroundColor:
            isSelected
                ? AppColors.primary
                : isDarkMode
                ? AppColors.tabInactiveDark
                : AppColors.tabInactive,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        _tabTitles[index],
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadChores,
      color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No chores assigned to you',
            style: AppTextStyles.dialogTitle.copyWith(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add chores to get started',
            style: AppTextStyles.bodyLarge.copyWith(
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithMessage(
    String title,
    String message,
    bool isDarkMode,
  ) {
    return RefreshIndicator(
      onRefresh: _loadChores,
      color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: 'Switzer',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    fontFamily: 'VarelaRound',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoresList(List<Map<String, dynamic>> chores, bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadChores,
      color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chores.length,
        itemBuilder: (context, index) {
          final choreAssignment = chores[index];
          final chore = choreAssignment['chores'] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChoreCard(choreAssignment, chore, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildChoreCard(
    Map<String, dynamic> assignment,
    Map<String, dynamic> chore,
    bool isDarkMode,
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
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
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
                      isCompleted
                          ? AppColors.primary
                          : isDarkMode
                          ? AppColors.borderDark
                          : AppColors.borderPrimary,
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
                  style: AppTextStyles.cardTitle.copyWith(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
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
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    _profileImageUrl != null
                        ? CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(_profileImageUrl!),
                        )
                        : CircleAvatar(
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
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
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
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
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
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
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
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
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
                title: Text(
                  'Edit Chore',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit chore screen
                },
              ),
              if (!isCompleted)
                ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.primary),
                  title: Text(
                    'Mark as Complete',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
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
                  title: Text(
                    'Mark as Pending',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _uncompleteChore(assignment['id']);
                  },
                ),
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: Text(
                  'Reassign Chore',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
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
                  _confirmDeleteChore(chore['id'], assignment['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated: Confirmation dialog now passes chore ID as well
  void _confirmDeleteChore(String choreId, String assignmentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

        return AlertDialog(
          title: Text(
            'Delete Chore',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this chore? This action cannot be undone.',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteChore(choreId, assignmentId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
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
