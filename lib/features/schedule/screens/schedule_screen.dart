// lib/features/schedule/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/features/chores/screens/add_chore_screen.dart';
import 'package:cleanslate/core/utils/string_extensions.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final _choreRepository = ChoreRepository();
  final _householdService = HouseholdService();
  final _supabaseService = SupabaseService();

  // View mode: 0 for week, 1 for month
  int _viewMode = 0;
  bool _isLoading = true;
  bool _showRecurringChores = false;
  String _userName = '';
  int _selectedNavIndex = 2; // Schedule tab selected

  // List to store regular and recurring chores
  List<Map<String, dynamic>> _chores = [];
  List<Map<String, dynamic>> _recurringChores = [];

  // Selected date related variables
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  // Animation controller for the bottom sheet slide
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Drag parameters
  double _dragStartY = 0;
  double _dragDistance = 0;
  final double _dragThreshold =
      50; // Threshold to close the card when dragging down

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChores();

    // Initialize animation controller for bottom sheet
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load user data from SupabaseService
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
      });
    }
  }

  Future<void> _loadChores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final householdId = _householdService.currentHousehold?.id;
      if (householdId == null) {
        // No household selected
        setState(() {
          _isLoading = false;
          _chores = [];
          _recurringChores = [];
        });
        return;
      }

      // Load all chores for the household
      final allChores = await _choreRepository.getChoresForHousehold(
        householdId,
      );

      // Separate regular and recurring chores
      final regular = <Map<String, dynamic>>[];
      final recurring = <Map<String, dynamic>>[];

      for (final chore in allChores) {
        if (chore['frequency'] != null && chore['frequency'] != 'once') {
          // This is a recurring chore
          recurring.add(chore);
        } else {
          // Regular chore - check if it has an assignment
          final assignments = chore['chore_assignments'] as List;
          if (assignments.isNotEmpty) {
            for (final assignment in assignments) {
              regular.add({...chore, 'assignment': assignment});
            }
          } else {
            regular.add(chore);
          }
        }
      }

      setState(() {
        _chores = regular;
        _recurringChores = recurring;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading chores: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to previous week/month
  void _navigatePrevious() {
    setState(() {
      if (_viewMode == 0) {
        // Week view
        _weekStart = _weekStart.subtract(const Duration(days: 7));
      } else {
        // Month view
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          1,
        );
      }
    });
  }

  // Navigate to next week/month
  void _navigateNext() {
    setState(() {
      if (_viewMode == 0) {
        // Week view
        _weekStart = _weekStart.add(const Duration(days: 7));
      } else {
        // Month view
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          1,
        );
      }
    });
  }

  // Select a specific day from the week or month view
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  // Format date to "Today" or "Tomorrow" or date string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateToCheck.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  // Toggle recurring chores section
  void _toggleRecurringChores() {
    setState(() {
      _showRecurringChores = !_showRecurringChores;

      if (_showRecurringChores) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Handle drag to close the card
  void _handleDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _dragDistance = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // Only allow dragging down, not up
    if (details.delta.dy > 0) {
      setState(() {
        _dragDistance = details.globalPosition.dy - _dragStartY;
        // Adjust the animation value based on drag distance
        final animationValue = (_animation.value - (_dragDistance / 300)).clamp(
          0.0,
          1.0,
        );
        _animationController.value = animationValue;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragDistance > _dragThreshold) {
      // Close the card if dragged beyond threshold
      setState(() {
        _showRecurringChores = false;
      });
      _animationController.reverse();
    } else {
      // Snap back if not dragged enough
      _animationController.forward();
    }

    // Reset drag values
    _dragDistance = 0;
  }

  // Mark a chore as complete or incomplete
  Future<void> _toggleChoreComplete(
    String assignmentId,
    bool currentStatus,
  ) async {
    try {
      if (currentStatus) {
        await _choreRepository.uncompleteChore(assignmentId);
      } else {
        await _choreRepository.completeChore(assignmentId);
      }

      // Refresh chores list
      _loadChores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating chore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          fontFamily: 'Switzer',
                        ),
                      ),
                    ],
                  ),
                ),

                // Week/Month toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.surfaceDark.withOpacity(0.6)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _viewMode == 0
                                        ? isDarkMode
                                            ? AppColors.surfaceDark
                                            : Colors.white
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Week',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? AppColors.textPrimaryDark
                                              : AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Switzer',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_today,
                                    color:
                                        isDarkMode
                                            ? AppColors.textPrimaryDark
                                            : AppColors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _viewMode == 1
                                        ? isDarkMode
                                            ? AppColors.surfaceDark
                                            : Colors.white
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Month',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? AppColors.textPrimaryDark
                                              : AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Switzer',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_month,
                                    color:
                                        isDarkMode
                                            ? AppColors.textPrimaryDark
                                            : AppColors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Calendar view (weekly or monthly)
                _viewMode == 0
                    ? _buildWeekView(isDarkMode)
                    : _buildMonthView(isDarkMode),

                const SizedBox(height: 16),

                // Chores section title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Use the first name when displaying the title
                        '${_userName.split(' ').first}\'s chores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          fontFamily: 'Switzer',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '0${_chores.length} tasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chores list
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
                          : ListView(
                            padding: const EdgeInsets.only(bottom: 100),
                            children: _buildChoresList(isDarkMode),
                          ),
                ),
              ],
            ),

            // Recurring Chores bottom sheet
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child:
                      _showRecurringChores
                          ? Transform.translate(
                            offset: Offset(0, (1 - _animation.value) * 300),
                            child: _buildRecurringChoresCard(isDarkMode),
                          )
                          : Container(),
                );
              },
            ),

            // FAB for toggling recurring chores - only visible when not showing recurring chores
            if (!_showRecurringChores)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: _toggleRecurringChores,
                    backgroundColor:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    elevation: 4.0,
                    child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
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
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            if (index != _selectedNavIndex) {
              setState(() {
                _selectedNavIndex = index;
              });

              // Handle navigation
              if (index == 0) {
                // Navigate to Home
                Navigator.pop(context);
              } else if (index == 1) {
                // Members tab
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MembersScreen(),
                  ),
                );
              } else if (index == 3) {
                // Settings tab
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            }
          },
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
                  _selectedNavIndex == 0
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
                  _selectedNavIndex == 1
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
                  _selectedNavIndex == 2
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
                  _selectedNavIndex == 3
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

  Widget _buildWeekView(bool isDarkMode) {
    final days = List.generate(7, (index) {
      return _weekStart.add(Duration(days: index));
    });

    return Column(
      children: [
        // Week scroller
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.navigate_before,
                color:
                    isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
              ),
              onPressed: _navigatePrevious,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_weekStart),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.navigate_next,
                color:
                    isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
              ),
              onPressed: _navigateNext,
            ),
          ],
        ),

        // Days of the week
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = days[index];
              final isSelected =
                  day.day == _selectedDate.day &&
                  day.month == _selectedDate.month &&
                  day.year == _selectedDate.year;
              final dayName = DateFormat('E').format(day).substring(0, 3);
              final isToday =
                  day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;

              return GestureDetector(
                onTap: () => _selectDate(day),
                child: Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? (isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isDarkMode
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary),
                          fontFamily: 'VarelaRound',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isToday
                                      ? (isDarkMode
                                          ? AppColors.primaryDark
                                          : AppColors.primary)
                                      : (isDarkMode
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary)),
                          fontWeight:
                              isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          fontFamily: 'Switzer',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(bool isDarkMode) {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Calculate the first day to display (might be in previous month)
    final firstDayIndex = firstDayOfMonth.weekday - 1; // 0 = Monday, 6 = Sunday
    final firstDay = firstDayOfMonth.subtract(Duration(days: firstDayIndex));

    // Calculate number of weeks to display
    final daysInMonth = lastDayOfMonth.day;
    final totalDays = firstDayIndex + daysInMonth;
    final totalWeeks = (totalDays / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // Month and Year with navigation - removed ">" after the date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.primary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.primary,
                    ),
                    onPressed: _navigatePrevious,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.primary,
                    ),
                    onPressed: _navigateNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((day) {
                  return SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary,
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar grid
          ...List.generate(totalWeeks, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final day = firstDay.add(
                    Duration(days: weekIndex * 7 + dayIndex),
                  );
                  final isCurrentMonth = day.month == month;
                  final isSelected =
                      day.day == _selectedDate.day &&
                      day.month == _selectedDate.month &&
                      day.year == _selectedDate.year;
                  final isToday =
                      day.day == DateTime.now().day &&
                      day.month == DateTime.now().month &&
                      day.year == DateTime.now().year;

                  return GestureDetector(
                    onTap: () => _selectDate(day),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (isDarkMode
                                    ? AppColors.primaryDark
                                    : AppColors.primary)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color:
                                !isCurrentMonth
                                    ? (isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[400])
                                    : (isSelected
                                        ? Colors.white
                                        : (isToday
                                            ? (isDarkMode
                                                ? AppColors.primaryDark
                                                : AppColors.primary)
                                            : (isDarkMode
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary))),
                            fontWeight:
                                isToday || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildChoresList(bool isDarkMode) {
    final displayedChores =
        _chores.where((chore) {
          // Filter chores by selected date if needed
          final assignment = chore['assignment'];
          if (assignment == null) return true;

          if (assignment['due_date'] != null) {
            final dueDate = DateTime.parse(assignment['due_date']);
            final selectedDate = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            );
            final choreDate = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
            );
            return choreDate.isAtSameMomentAs(selectedDate);
          }
          return true;
        }).toList();

    if (displayedChores.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No chores scheduled for this day',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: 'VarelaRound',
              ),
            ),
          ),
        ),
      ];
    }

    return displayedChores.map((chore) {
      final assignment = chore['assignment'];
      final isCompleted =
          assignment != null && assignment['status'] == 'completed';
      final dueDate =
          assignment != null && assignment['due_date'] != null
              ? DateTime.parse(assignment['due_date'])
              : null;

      // Determine priority color
      Color priorityColor = AppColors.priorityMedium;
      if (assignment != null) {
        switch ((assignment['priority'] ?? 'medium').toLowerCase()) {
          case 'high':
            priorityColor = AppColors.priorityHigh;
            break;
          case 'low':
            priorityColor = AppColors.priorityLow;
            break;
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
            ),
            color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: GestureDetector(
              onTap: () {
                if (assignment != null) {
                  _toggleChoreComplete(assignment['id'], isCompleted);
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
                            ? (isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary)
                            : (isDarkMode
                                ? AppColors.borderDark
                                : Colors.grey[400]!),
                    width: 2,
                  ),
                  color:
                      isCompleted
                          ? (isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary)
                          : Colors.transparent,
                ),
                child:
                    isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
              ),
            ),
            title: Text(
              chore['name'] ?? 'Untitled Chore',
              style: TextStyle(
                fontFamily: 'VarelaRound',
                fontWeight: FontWeight.w500,
                color:
                    isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dueDate != null ? _formatDate(dueDate) : 'No due date',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 12, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        StringExtension(
                          (assignment != null && assignment['priority'] != null)
                              ? assignment['priority'].toString()
                              : 'Medium',
                        ).capitalize(),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'VarelaRound',
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    size: 16,
                  ),
                  onPressed: () {
                    // Show chore options menu
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Build the recurring chores card as a half-screen popup with drag to close
  Widget _buildRecurringChoresCard(bool isDarkMode) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.primary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Recurring Chores header with sync icon and Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recurring Chores',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          fontFamily: 'Switzer',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.sync,
                        color:
                            isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddChoreScreen(),
                        ),
                      ).then((_) => _loadChores());
                    },
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recurring chores list
            _recurringChores.isEmpty
                ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No recurring chores set up yet',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                  ),
                )
                : Container(
                  constraints: BoxConstraints(
                    // Limit the height to make it a half-screen popup
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    itemCount: _recurringChores.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final chore = _recurringChores[index];
                      final frequency = chore['frequency'] ?? 'weekly';
                      String frequencyText;
                      String dayText = '';

                      switch (frequency.toLowerCase()) {
                        case 'daily':
                          frequencyText = 'Daily';
                          break;
                        case 'weekly':
                          frequencyText = 'Weekly';
                          dayText = '× Tuesday';
                          break;
                        case 'monthly':
                          frequencyText = 'Monthly';
                          break;
                        case 'biweekly':
                          frequencyText = 'Twice a week';
                          dayText = '× Mon,Tue';
                          break;
                        default:
                          frequencyText = 'Weekly';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? AppColors.primaryDark
                                      : AppColors.primary,
                            ),
                            color:
                                isDarkMode
                                    ? AppColors.backgroundDark
                                    : Colors.white,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? AppColors.borderDark
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                            ),
                            title: Text(
                              chore['name'] ?? 'Untitled Chore',
                              style: TextStyle(
                                fontFamily: 'VarelaRound',
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$frequencyText $dayText',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDarkMode
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                    fontFamily: 'VarelaRound',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color:
                                        isDarkMode
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    // Show chore options menu
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
