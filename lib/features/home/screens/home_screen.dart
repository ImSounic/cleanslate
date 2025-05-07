// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';

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
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  SvgPicture.asset(
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
                  const SizedBox(width: 12),
                  // Profile
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      color: AppColors.textLight,
                      size: 18,
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
                      : _buildChoresList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: AppColors.textLight),
        onPressed: () {
          // Show dialog to create a new chore
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
            // else if (index == 2) { // Calendar
            //   await Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarScreen()));
            //   setState(() {
            //     _selectedNavIndex = 0;
            //   });
            // }
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

  Widget _buildChoresList() {
    // Example data based on the design
    final demoChores = [
      {
        'name': 'Buy milk',
        'assignee': 'Emma',
        'assigneeInitial': 'E',
        'avatarColor': AppColors.avatarAmber,
        'priority': 'High',
        'priorityColor': AppColors.priorityHigh,
        'due': 'Today',
        'completed': false,
      },
      {
        'name': 'Take out Trash',
        'assignee': 'Jack',
        'assigneeInitial': 'J',
        'avatarColor': AppColors.avatarGreen,
        'priority': 'High',
        'priorityColor': AppColors.priorityHigh,
        'due': 'Today',
        'completed': false,
      },
      {
        'name': 'Vaccum The Hall',
        'assignee': 'Dad',
        'assigneeInitial': 'D',
        'avatarColor': AppColors.avatarBrown,
        'priority': 'Low',
        'priorityColor': AppColors.priorityLow,
        'due': 'Tomorrow',
        'completed': false,
      },
      {
        'name': 'Do Laundry',
        'assignee': 'Mom',
        'assigneeInitial': 'M',
        'avatarColor': AppColors.avatarPurple,
        'priority': 'Medium',
        'priorityColor': AppColors.priorityMedium,
        'due': 'Tomorrow',
        'completed': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demoChores.length,
      itemBuilder: (context, index) {
        final chore = demoChores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChoreCard(chore),
        );
      },
    );
  }

  Widget _buildChoreCard(Map<String, dynamic> chore) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          // Completion circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    chore['completed']
                        ? AppColors.primary
                        : AppColors.borderPrimary,
                width: 2,
              ),
              color:
                  chore['completed'] ? AppColors.primary : Colors.transparent,
            ),
            child:
                chore['completed']
                    ? Icon(Icons.check, color: AppColors.textLight, size: 16)
                    : null,
          ),
          const SizedBox(width: 16),
          // Chore details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chore['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Switzer',
                    color: AppColors.textPrimary,
                    decoration:
                        chore['completed'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
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
                      backgroundColor: chore['avatarColor'],
                      child: Text(
                        chore['assigneeInitial'],
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          fontFamily: 'VarelaRound',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chore['assignee'],
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      'assets/images/icons/scroll_description.svg',
                      height: 12,
                      width: 12,
                      colorFilter: ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Priority and due date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/icons/flag.svg',
                    height: 14,
                    width: 14,
                    colorFilter: ColorFilter.mode(
                      chore['priorityColor'],
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chore['priority'],
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'VarelaRound',
                      color: chore['priorityColor'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
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
                    chore['due'],
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
          const SizedBox(width: 12),
          // More options
          Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
