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
import 'package:cleanslate/features/app_shell.dart';
import 'package:cleanslate/features/settings/screens/edit_profile_screen.dart';
import 'package:cleanslate/features/household/screens/household_detail_screen.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/core/utils/string_extensions.dart';
import 'package:cleanslate/widgets/theme_toggle_button.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'package:cleanslate/data/services/chore_assignment_service.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:cleanslate/data/services/recurrence_service.dart';
import 'package:cleanslate/features/chores/screens/edit_chore_screen.dart';
import 'package:intl/intl.dart';
import 'package:cleanslate/core/services/error_service.dart';

import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/features/notifications/screens/notifications_screen.dart';
import 'package:cleanslate/features/stats/screens/chore_stats_screen.dart';
import 'package:cleanslate/data/services/chore_initialization_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    {
  final _supabaseService = SupabaseService();
  final _choreRepository = ChoreRepository();
  final _householdRepository = HouseholdRepository();
  String _userName = '';
  String? _profileImageUrl; // Added property for profile image URL
  List<Map<String, dynamic>> _myChores = []; // pending
  List<Map<String, dynamic>> _completedChores = [];
  List<Map<String, dynamic>> _householdChores = []; // All household chores for filter
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  
  // User filter for "Assigned to" tab
  List<HouseholdMemberModel> _householdMembers = [];
  String? _selectedMemberFilter; // null = All, or user_id
  
  // User filter for "Completed" tab
  String? _selectedCompletedMemberFilter; // null = All, or user_id

  // Chore initialization tracking
  bool _choresInitialized = true; // Default true to avoid flash
  bool _needsRebalance = false;
  bool _isInitializing = false;

  // Tab titles
  final List<String> _tabTitles = [
    'My Tasks',
    'Assigned to',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChores();
    _loadHouseholdMembers();
    _processRecurringChores();
    _checkInitializationStatus();
  }

  /// Check if chores have been initialized for this household.
  Future<void> _checkInitializationStatus() async {
    try {
      final household = HouseholdService().currentHousehold;
      if (household == null) return;

      // Reload household to get latest data
      final freshHousehold = await _householdRepository.getHouseholdModel(household.id);
      HouseholdService().setCurrentHousehold(freshHousehold);

      final initService = ChoreInitializationService();
      final needsRebalance = await initService.needsRebalance(
        freshHousehold,
        _householdMembers.length,
      );

      if (mounted) {
        setState(() {
          _choresInitialized = freshHousehold.choresInitialized;
          _needsRebalance = needsRebalance;
        });
      }
    } catch (e) {
      debugLog('Failed to check initialization status: $e');
    }
  }

  /// Handle rebalance when new members join.
  Future<void> _handleRebalance() async {
    setState(() => _isInitializing = true);

    try {
      final household = HouseholdService().currentHousehold;
      if (household == null) throw Exception('No household');

      final memberIds = _householdMembers.map((m) => m.userId).toList();
      
      final initService = ChoreInitializationService();
      final count = await initService.rebalanceChores(
        householdId: household.id,
        memberIds: memberIds,
      );

      // Reload everything
      await _loadChores();
      await _checkInitializationStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chores rebalanced! $count reassigned.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'rebalanceChores');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _loadHouseholdMembers() async {
    try {
      final household = HouseholdService().currentHousehold;
      if (household == null) return;
      
      final members = await _householdRepository.getHouseholdMembers(household.id);
      if (mounted) {
        setState(() {
          _householdMembers = members;
        });
        // Check if rebalance needed after members are loaded
        _checkInitializationStatus();
      }
    } catch (e) {
      debugLog('Failed to load household members: $e');
    }
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

  /// Public method to refresh chores (called from AppShell after adding a chore)
  void refreshChores() {
    _loadChores();
  }

  Future<void> _loadChores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = _supabaseService.currentUser?.id;
      debugLog('📋 _loadChores: currentUserId=$currentUserId');
      
      final chores = await _choreRepository.getMyChores();
      debugLog('📋 _loadChores: fetched ${chores.length} chores');

      // Separate chores by status
      final completed = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];

      for (final chore in chores) {
        final status = chore['status'] ?? 'pending';
        final assignedTo = chore['assigned_to'];
        final choreData = chore['chores'] as Map<String, dynamic>?;
        
        // Skip recurring TEMPLATES (only show generated instances)
        // Templates have frequency != 'once' AND recurrence_parent_id is null
        final frequency = choreData?['frequency'];
        final recurrenceParentId = choreData?['recurrence_parent_id'];
        final isRecurringTemplate = frequency != null && 
            frequency != 'once' && 
            recurrenceParentId == null;
        
        if (isRecurringTemplate) {
          debugLog('📋 Skipping recurring template: ${choreData?['name']}');
          continue; // Skip templates, they're managed through recurrence system
        }
        
        debugLog('📋 Chore: ${choreData?['name']} | status=$status | assigned_to=$assignedTo');
        
        if (status == 'completed') {
          completed.add(chore);
        } else {
          // Both pending and in_progress go to My Tasks
          pending.add(chore);
        }
      }

      debugLog('📋 Results: pending=${pending.length}, completed=${completed.length}');

      // Also load all household chores for the filter view
      final householdId = HouseholdService().currentHousehold?.id;
      List<Map<String, dynamic>> householdChores = [];
      if (householdId != null) {
        try {
          final allChores = await _choreRepository.getChoresForHousehold(householdId);
          // Flatten to include assignments
          for (final chore in allChores) {
            // Skip recurring TEMPLATES (only show generated instances)
            final frequency = chore['frequency'];
            final recurrenceParentId = chore['recurrence_parent_id'];
            final isRecurringTemplate = frequency != null && 
                frequency != 'once' && 
                recurrenceParentId == null;
            
            if (isRecurringTemplate) {
              continue; // Skip templates
            }
            
            final assignments = chore['chore_assignments'] as List? ?? [];
            for (final assignment in assignments) {
              if (assignment['status'] != 'completed') {
                householdChores.add({...chore, ...assignment, 'chores': chore});
              }
            }
          }
        } catch (e) {
          debugLog('Failed to load household chores: $e');
        }
      }

      setState(() {
        _myChores = pending;
        _completedChores = completed;
        _householdChores = householdChores;
      });
    } catch (e) {
      debugLog('❌ _loadChores error: $e');
      // Handle error
      if (mounted) {
        ErrorService.showError(context, e, operation: 'loadChores');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check and generate any missed recurring chore instances on app open.
  Future<void> _processRecurringChores() async {
    final householdId = HouseholdService().currentHousehold?.id;
    if (householdId == null) return;

    final recurrenceService = RecurrenceService();
    final generated =
        await recurrenceService.processAllRecurringChores(householdId);

    if (generated > 0 && mounted) {
      // Refresh the list to show new instances
      _loadChores();
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.home_outlined,
                  title: 'Household Settings',
                  onTap: () {
                    Navigator.pop(context);
                    final household = HouseholdService().currentHousehold;
                    if (household != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HouseholdDetailScreen(
                            householdId: household.id,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No household selected. Join or create one first.'),
                        ),
                      );
                    }
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Settings tab (index 3) in AppShell
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AppShell(initialIndex: 3),
                      ),
                      (route) => false,
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
                  themeProvider.toggleTheme();
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
        ErrorService.showError(context, e, operation: 'logout');
      }
    }
  }

  Future<void> _completeChore(
    String assignmentId, {
    String? choreId,
    String? householdId,
  }) async {
    try {
      await _choreRepository.completeChore(assignmentId);

      // Trigger recurring chore generation if applicable
      if (choreId != null) {
        final hId =
            householdId ?? HouseholdService().currentHousehold?.id;
        if (hId != null) {
          final recurrenceService = RecurrenceService();
          final next = await recurrenceService.onChoreCompleted(
            choreId: choreId,
            assignmentId: assignmentId,
            householdId: hId,
          );
          if (next != null && mounted) {
            final freq = next['frequency'] ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Next "${next['name']}" scheduled ($freq)',
                ),
              ),
            );
          }
        }
      }

      // Refresh chores list
      _loadChores();
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'completeChore');
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
        ErrorService.showError(context, e, operation: 'uncompleteChore');
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
        ErrorService.showError(context, e, operation: 'deleteChore');
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
                              backgroundColor: AppColors.avatarColorFor(
                                _supabaseService.currentUser?.id ?? _userName,
                              ),
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

    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with icons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Theme toggle — uses shared widget
                      const ThemeToggleButton(),
                  const SizedBox(width: 12),
                  // Stats icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChoreStatsScreen(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 24,
                      color: isDarkMode
                          ? AppColors.iconPrimaryDark
                          : AppColors.iconPrimary,
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
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),
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
        // Assign Chores / Rebalance button (bottom left)
        if (!_choresInitialized || _needsRebalance)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildAssignRebalanceButton(isDarkMode),
          ),
        ],
      ),
    );
  }

  /// Build the Assign/Rebalance floating button
  Widget _buildAssignRebalanceButton(bool isDarkMode) {
    final isRebalance = _choresInitialized && _needsRebalance;
    
    return FloatingActionButton.extended(
      heroTag: 'assign_rebalance_fab',
      onPressed: _isInitializing ? null : () async {
        if (isRebalance) {
          await _handleRebalance();
        } else {
          await _handleAssignChores();
        }
      },
      backgroundColor: isRebalance ? Colors.orange : AppColors.primary,
      icon: _isInitializing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              isRebalance ? Icons.balance : Icons.auto_awesome,
              color: Colors.white,
            ),
      label: Text(
        _isInitializing
            ? 'Working...'
            : isRebalance
                ? 'Rebalance'
                : 'Assign Chores',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'VarelaRound',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Handle auto-assignment of chores
  Future<void> _handleAssignChores() async {
    setState(() => _isInitializing = true);

    try {
      final household = HouseholdService().currentHousehold;
      if (household == null) throw Exception('No household');

      final memberIds = _householdMembers.map((m) => m.userId).toList();
      if (memberIds.isEmpty) {
        throw Exception('No members in household');
      }

      final initService = ChoreInitializationService();
      final count = await initService.initializeChores(
        household: household,
        memberIds: memberIds,
      );

      // Reload fresh household data to get updated choresInitialized flag
      final freshHousehold = await _householdRepository.getHouseholdModel(household.id);
      HouseholdService().setCurrentHousehold(freshHousehold);

      // Update local state immediately
      if (mounted) {
        setState(() {
          _choresInitialized = true;
          _needsRebalance = false;
        });
      }

      // Reload chores
      await _loadChores();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count chores assigned! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'assignChores');
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  // Method to show appropriate content based on selected tab
  Widget _buildChoreContent(bool isDarkMode) {
    // Show appropriate content based on selected tab
    switch (_selectedTabIndex) {
      case 0: // My Tasks
        return _myChores.isEmpty
            ? _buildEmptyState(isDarkMode)
            : _buildChoresList(_myChores, isDarkMode);
      case 1: // Assigned to - with user filter
        return _buildAssignedToWithFilter(isDarkMode);
      case 2: // Completed - with user filter
        return _buildCompletedWithFilter(isDarkMode);
      default:
        return _buildEmptyState(isDarkMode);
    }
  }

  // Build "Assigned to" view with user filter chips
  Widget _buildAssignedToWithFilter(bool isDarkMode) {
    // Filter chores based on selected member
    List<Map<String, dynamic>> filteredChores;
    if (_selectedMemberFilter == null) {
      // Show all household chores
      filteredChores = _householdChores;
    } else {
      // Filter by selected member
      filteredChores = _householdChores
          .where((c) => c['assigned_to'] == _selectedMemberFilter)
          .toList();
    }

    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('All'),
                  selected: _selectedMemberFilter == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedMemberFilter = null;
                    });
                  },
                  selectedColor: isDarkMode 
                      ? AppColors.primaryDark.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedMemberFilter == null
                        ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
              // Member chips
              ..._householdMembers.map((member) {
                final isSelected = _selectedMemberFilter == member.userId;
                final isMe = member.userId == _supabaseService.currentUser?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: member.profileImageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(member.profileImageUrl!),
                            radius: 12,
                          )
                        : CircleAvatar(
                            backgroundColor: AppColors.avatarColorFor(member.userId),
                            radius: 12,
                            child: Text(
                              (member.fullName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                    label: Text(isMe ? 'Me' : (member.fullName?.split(' ').first ?? 'User')),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMemberFilter = isSelected ? null : member.userId;
                      });
                    },
                    selectedColor: isDarkMode 
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                          : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chores list
        Expanded(
          child: filteredChores.isEmpty
              ? _buildEmptyStateWithMessage(
                  _selectedMemberFilter == null 
                      ? 'No assigned chores'
                      : 'No chores for this member',
                  'Chores assigned to household members will appear here',
                  isDarkMode,
                )
              : _buildChoresList(filteredChores, isDarkMode),
        ),
      ],
    );
  }

  // Build "Completed" view with user filter chips
  Widget _buildCompletedWithFilter(bool isDarkMode) {
    // Filter completed chores based on selected member
    List<Map<String, dynamic>> filteredChores;
    if (_selectedCompletedMemberFilter == null) {
      // Show all completed chores
      filteredChores = _completedChores;
    } else {
      // Filter by selected member (who was assigned when completed)
      filteredChores = _completedChores
          .where((c) => c['assigned_to'] == _selectedCompletedMemberFilter)
          .toList();
    }

    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCompletedMemberFilter == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCompletedMemberFilter = null;
                    });
                  },
                  selectedColor: isDarkMode 
                      ? AppColors.primaryDark.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedCompletedMemberFilter == null
                        ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
              // Member chips
              ..._householdMembers.map((member) {
                final isSelected = _selectedCompletedMemberFilter == member.userId;
                final isMe = member.userId == _supabaseService.currentUser?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: member.profileImageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(member.profileImageUrl!),
                          )
                        : null,
                    label: Text(isMe ? 'Me' : (member.fullName ?? member.email ?? 'User')),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCompletedMemberFilter = member.userId;
                      });
                    },
                    selectedColor: isDarkMode 
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                          : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chores list
        Expanded(
          child: filteredChores.isEmpty
              ? _buildEmptyStateWithMessage(
                  _selectedCompletedMemberFilter == null
                      ? 'No completed chores'
                      : 'No completed chores for this member',
                  'Complete your tasks to see them here',
                  isDarkMode,
                )
              : _buildChoresList(filteredChores, isDarkMode),
        ),
      ],
    );
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
        // Add cacheExtent for smoother scrolling
        cacheExtent: 200,
        itemBuilder: (context, index) {
          final choreAssignment = chores[index];
          final chore = choreAssignment['chores'] as Map<String, dynamic>;
          // Wrap each card in RepaintBoundary to prevent unnecessary repaints
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChoreCard(choreAssignment, chore, isDarkMode),
            ),
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

    // Determine status
    final status = assignment['status'] ?? 'pending';
    final isCompleted = status == 'completed';

    // Get assignee info from household members
    final assignedToId = assignment['assigned_to'] as String?;
    final assigneeMember = _householdMembers.firstWhere(
      (m) => m.userId == assignedToId,
      orElse: () => HouseholdMemberModel(
        id: '', householdId: '', userId: assignedToId ?? '', 
        role: '', joinedAt: DateTime.now(), isActive: true,
        fullName: _userName,
      ),
    );
    final assigneeFullName = assigneeMember.fullName ?? _userName;
    final assigneeFirstName = assigneeFullName.split(' ').first;
    final assigneeImageUrl = assigneeMember.profileImageUrl;
    final assigneeId = assigneeMember.userId;

    // Get assigner info from household members (who assigned the chore)
    final assignedById = assignment['assigned_by'] as String?;
    HouseholdMemberModel? assignerMember;
    if (assignedById != null) {
      try {
        assignerMember = _householdMembers.firstWhere(
          (m) => m.userId == assignedById,
        );
      } catch (_) {
        assignerMember = null;
      }
    }
    final assignerFullName = assignerMember?.fullName;
    final assignerFirstName = assignerFullName?.split(' ').first;
    final assignerImageUrl = assignerMember?.profileImageUrl;
    final assignerId = assignerMember?.userId;

    // Check if chore has description
    final hasDescription =
        chore['description'] != null &&
        chore['description'].toString().isNotEmpty;

    // Check if this is a recurring chore
    final frequency = chore['frequency'] as String?;
    final isRecurring = frequency != null && frequency != 'once';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      // Increased height to accommodate both Assigned to and Assigned by
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN - Completion circle for the entire height
          GestureDetector(
            onTap: () {
              if (isCompleted) {
                _uncompleteChore(assignment['id']);
              } else {
                _completeChore(
                  assignment['id'],
                  choreId: chore['id'],
                );
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : isDarkMode
                          ? AppColors.borderDark
                          : AppColors.borderPrimary,
                  width: 2,
                ),
                color: isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
              ),
              child: isCompleted
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
                // TOP ROW - Title only (recurring indicator moved to bottom right)
                Text(
                  chore['name'] ?? 'Unnamed Chore',
                  style: AppTextStyles.cardTitle.copyWith(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // ASSIGNED TO ROW
                Row(
                  children: [
                    Text(
                      'Assigned to: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'VarelaRound',
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    assigneeImageUrl != null
                        ? CircleAvatar(
                          radius: 8,
                          backgroundImage: NetworkImage(assigneeImageUrl),
                        )
                        : CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.avatarColorFor(assigneeId),
                          child: Text(
                            assigneeFirstName.isNotEmpty 
                                ? assigneeFirstName[0].toUpperCase() 
                                : 'U',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textLight,
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                        ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        assigneeFirstName,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'VarelaRound',
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Description icon
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
                            height: 12,
                            width: 12,
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

                const SizedBox(height: 4),

                // ASSIGNED BY ROW (only show if different from assignee or if assigner exists)
                if (assignerFirstName != null && assignerId != null)
                  Row(
                    children: [
                      Text(
                        'Assigned by: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'VarelaRound',
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                      ),
                      assignerImageUrl != null
                          ? CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage(assignerImageUrl),
                          )
                          : CircleAvatar(
                            radius: 8,
                            backgroundColor: AppColors.avatarColorFor(assignerId),
                            child: Text(
                              assignerFirstName.isNotEmpty 
                                  ? assignerFirstName[0].toUpperCase() 
                                  : 'U',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.textLight,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                          ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          assignerFirstName,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'VarelaRound',
                            color:
                                isDarkMode
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Spacer to push recurring indicator to bottom
                const Spacer(),
                
                // BOTTOM LEFT - Recurring indicator
                if (isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.autorenew,
                          size: 10,
                          color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatFrequency(frequency),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'VarelaRound',
                            color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    (assignment['priority'] ?? 'Medium').toString().capitalize(),
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

              // BOTTOM RIGHT - Due date only
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
    final status = assignment['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Chore
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: Text(
                  'Edit Chore',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditChoreScreen(
                        chore: chore,
                        assignment: assignment,
                      ),
                    ),
                  );
                  if (changed == true) _loadChores();
                },
              ),

              // Mark as Complete
              if (!isCompleted)
                ListTile(
                  leading:
                      Icon(Icons.check_circle, color: AppColors.primary),
                  title: Text(
                    'Mark as Complete',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _completeChore(
                      assignment['id'],
                      choreId: chore['id'],
                    );
                  },
                ),

              // Mark as Pending (from completed)
              if (isCompleted)
                ListTile(
                  leading: Icon(
                    Icons.radio_button_unchecked,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Mark as Pending',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _uncompleteChore(assignment['id']);
                  },
                ),

              // Reassign Chore
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: Text(
                  'Reassign Chore',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReassignSheet(assignment, chore);
                },
              ),

              // Delete Chore
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Chore',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteChore(chore['id'], assignment['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show bottom sheet to reassign a chore to another household member.
  Future<void> _showReassignSheet(
    Map<String, dynamic> assignment,
    Map<String, dynamic> chore,
  ) async {
    final household = HouseholdService().currentHousehold;
    if (household == null) return;

    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // Load members and their workload in parallel
    final householdRepo = HouseholdRepository();
    final assignmentService = ChoreAssignmentService();

    final members = await householdRepo.getHouseholdMembers(household.id);
    final workloadCounts = await assignmentService.getRecentAssignmentCounts(
      household.id,
      days: 7,
    );

    // Get algorithm recommendation
    final recommendation = await assignmentService.getRecommendation(
      householdId: household.id,
      choreName: chore['name'] ?? '',
      dueDate: assignment['due_date'] != null
          ? DateTime.parse(assignment['due_date'])
          : DateTime.now(),
    );

    if (!mounted) return;

    final currentAssignee = assignment['assigned_to'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Reassign "${chore['name']}"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Switzer',
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...members.map((member) {
                final isCurrent = member.userId == currentAssignee;
                final isRecommended =
                    recommendation != null &&
                    member.userId == recommendation.userId;
                final workload = workloadCounts[member.userId] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isCurrent
                        ? AppColors.primary
                        : (isDarkMode
                            ? AppColors.surfaceDark
                            : Colors.grey[200]),
                    backgroundImage: member.profileImageUrl != null
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? Text(
                            (member.fullName ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color:
                                  isCurrent ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(
                        member.fullName ?? member.email ?? 'User',
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '(current)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (isRecommended)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '$workload chore${workload == 1 ? '' : 's'} this week'
                    '${isRecommended ? ' · Recommended' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color: isRecommended
                          ? (isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary)
                          : (isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
                  ),
                  onTap: isCurrent
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          try {
                            await _choreRepository.updateChoreAssignment(
                              assignmentId: assignment['id'],
                              assignedTo: member.userId,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reassigned to ${member.fullName ?? 'member'}',
                                  ),
                                ),
                              );
                            }
                            await _loadChores();
                          } catch (e) {
                            if (mounted) {
                              ErrorService.showError(context, e, operation: 'reassignChore');
                            }
                          }
                        },
                );
              }),
              const SizedBox(height: 8),
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

  // capitalize helper moved to string_extensions.dart

  /// Format frequency for display on chore card
  String _formatFrequency(String? frequency) {
    switch (frequency?.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      case 'weekdays':
        return 'Weekdays';
      case 'weekends':
        return 'Weekends';
      default:
        return 'Recurring';
    }
  }
}
