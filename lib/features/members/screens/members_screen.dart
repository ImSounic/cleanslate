// lib/features/members/screens/members_screen.dart
// ignore_for_file: use_super_parameters, use_build_context_synchronously, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/features/members/screens/admin_mode_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({Key? key}) : super(key: key);

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final HouseholdService _householdService = HouseholdService();
  final TextEditingController _householdNameController =
      TextEditingController();
  final TextEditingController _householdCodeController =
      TextEditingController();

  int _selectedNavIndex = 1; // Members tab selected

  List<HouseholdMemberModel> _members = [];
  bool _isLoading = true;
  String _householdName = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _householdNameController.dispose();
    _householdCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current household
      final currentHousehold = _householdService.currentHousehold;
      if (currentHousehold == null) {
        // Handle case when no household is selected
        setState(() {
          _isLoading = false;
          _householdName = 'No Household Selected';
          _members = [];
        });
        return;
      }

      setState(() {
        _householdName = currentHousehold.name;
      });

      // Fetch members for the current household
      final members = await _householdRepository.getHouseholdMembers(
        currentHousehold.id,
      );

      if (!mounted) return;

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading members: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading members: $e')));
    }
  }

  Future<void> _refreshHouseholdData() async {
    await _loadMembers();
  }

  Future<void> _createHousehold(String name) async {
    // Capture context before async operations
    final BuildContext currentContext = context;

    setState(() {
      _isLoading = true;
    });

    try {
      await _householdService.createAndSetHousehold(name);

      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Refresh members with new household
      await _loadMembers();

      // Check again if mounted before showing success message
      if (!mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Household "$name" created successfully!')),
      );
    } catch (e) {
      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create household: $e';
      });

      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('Error creating household: $e')));
    }
  }

  Future<void> _joinHousehold(String code) async {
  // Capture context before async operations
  final BuildContext currentContext = context;

  setState(() {
    _isLoading = true;
    _errorMessage = null; // Clear previous errors
  });

  try {
    print("Starting join household process with code: $code");
    await _householdRepository.joinHouseholdWithCode(code);

    // Initialize household service to set the current household
    await _householdService.initializeHousehold();

    // Check if widget is still mounted before updating UI
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Refresh members with new household
    await _loadMembers();

    // Check again if mounted before showing success message
    if (!mounted) return;

    ScaffoldMessenger.of(
      currentContext,
    ).showSnackBar(SnackBar(content: Text('Successfully joined household!')));
  } catch (e) {
    // Check if widget is still mounted before updating UI
    if (!mounted) return;

    print("Error joining household: $e");
    
    setState(() {
      _isLoading = false;
      // Extract meaningful error message from exception
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.split('Exception: ')[1];
      }
      _errorMessage = 'Failed to join household: $errorMsg';
    });

    ScaffoldMessenger.of(
      currentContext,
    ).showSnackBar(SnackBar(content: Text(_errorMessage ?? 'Error joining household')));
  }
}
  void _showHouseholdCode(String code) {
    // IMPORTANT: Access theme provider with listen: false to avoid the error
    // Get the current theme state before going into the dialog builder
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Household Code',
            style: TextStyle(
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this code with others to invite them to your household:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: 'VarelaRound',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // Copy to clipboard when tapped
                    Clipboard.setData(ClipboardData(text: code));

                    // Show a snackbar to confirm copy action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, // Reduced padding
                      vertical: 12, // Reduced padding
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.backgroundDark
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Make row take minimum space
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            code,
                            style: TextStyle(
                              fontSize: 20, // Slightly smaller font
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1, // Reduced letter spacing
                              color: AppColors.primary,
                              fontFamily: 'Switzer',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8), // Reduced space
                        Icon(
                          Icons.copy,
                          color: AppColors.primary,
                          size: 20,
                        ), // Smaller icon
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to copy',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateHouseholdDialog() {
    // Use Provider with listen: false
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Clear previous input
    _householdNameController.clear();

    // Capture context before showing dialog
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Create New Household',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          content: TextField(
            controller: _householdNameController,
            decoration: InputDecoration(
              hintText: 'Enter household name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintStyle: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: 'VarelaRound',
              ),
            ),
            autofocus: true,
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'VarelaRound',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final householdName = _householdNameController.text.trim();
                if (householdName.isEmpty) {
                  // Show validation error in the dialog context
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a household name'),
                    ),
                  );
                  return;
                }

                // Close the dialog first
                Navigator.pop(dialogContext);

                // Call create household method
                _createHousehold(householdName);
              },
              child: Text(
                'Create',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showJoinHouseholdDialog() {
    // Use Provider with listen: false
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Clear previous input
    _householdCodeController.clear();

    // Capture context before showing dialog
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Join Household',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          content: TextField(
            controller: _householdCodeController,
            decoration: InputDecoration(
              hintText: 'Enter 8-character code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintStyle: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: 'VarelaRound',
              ),
            ),
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'VarelaRound',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final householdCode =
                    _householdCodeController.text.trim().toUpperCase();
                if (householdCode.length != 8) {
                  // Show validation error in the dialog context
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid 8-character code'),
                    ),
                  );
                  return;
                }

                // Close the dialog first
                Navigator.pop(dialogContext);

                // Call join household method
                _joinHousehold(householdCode);
              },
              child: Text(
                'Join',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditMemberDialog(HouseholdMemberModel member) {
    // Use Provider with listen: false
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Edit Member',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${member.fullName ?? 'N/A'}',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  fontFamily: 'VarelaRound',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${member.email ?? 'N/A'}',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  fontFamily: 'VarelaRound',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Role:',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  fontFamily: 'VarelaRound',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: member.role,
                isExpanded: true,
                dropdownColor:
                    isDarkMode ? AppColors.surfaceDark : AppColors.surface,
                items:
                    ['member', 'admin'].map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          _capitalizeRole(role),
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newRole) {
                  if (newRole != null) {
                    Navigator.pop(dialogContext);
                    _updateMemberRole(member.id, newRole);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmRemoveMember(member);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(
                'Remove Member',
                style: TextStyle(fontFamily: 'VarelaRound'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    // Capture context before async operations
    final BuildContext currentContext = context;

    try {
      await _householdRepository.updateMemberRole(memberId, newRole);

      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      // Refresh members list
      await _loadMembers();

      // Check again if mounted before showing success message
      if (!mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Member role updated successfully')),
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('Error updating member role: $e')));
    }
  }

  void _confirmRemoveMember(HouseholdMemberModel member) {
    // Use Provider with listen: false
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Capture context before showing dialog
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Remove Member',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          content: Text(
            'Are you sure you want to remove ${member.fullName ?? 'this member'} from the household?',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'VarelaRound',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _removeMember(member.id);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(
                'Remove',
                style: TextStyle(fontFamily: 'VarelaRound'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeMember(String memberId) async {
    // Capture context before async operations
    final BuildContext currentContext = context;

    try {
      await _householdRepository.removeMemberFromHousehold(memberId);

      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      // Refresh members list
      await _loadMembers();

      // Check again if mounted before showing success message
      if (!mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
    }
  }

  // Navigate to Admin Mode screen
  void _navigateToAdminMode() {
    if (_householdService.currentHousehold != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminModeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No household selected. Create or join a household first.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check dark mode
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button, search bar and code button section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      // Search bar
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? AppColors.surfaceDark
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? AppColors.borderDark
                                      : AppColors.border,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                              fontFamily: 'VarelaRound',
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search for members',
                              hintStyle: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                fontFamily: 'VarelaRound',
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color:
                                    isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                maxWidth: 36,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                            ),
                            textAlignVertical: TextAlignVertical.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Code button
                      ElevatedButton(
                        onPressed: () {
                          // Show household code
                          if (_householdService.currentHousehold != null) {
                            _showHouseholdCode(
                              _householdService.currentHousehold!.code,
                            );
                          } else {
                            // Show options if no household is selected
                            _showNoHouseholdOptionsDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Room Code',
                          style: TextStyle(
                            fontFamily: 'VarelaRound',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Members title and count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 38,
                          fontFamily: 'Switzer',
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                        ),
                      ),
                      Text(
                        _householdName,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'VarelaRound',
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Members list or content based on state
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshHouseholdData,
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    backgroundColor:
                        isDarkMode ? AppColors.surfaceDark : Colors.white,
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
                            : _errorMessage != null
                            ? _buildErrorView(isDarkMode)
                            : _householdService.currentHousehold == null
                            ? _buildNoHouseholdView(isDarkMode)
                            : _buildMembersListWithAddContent(isDarkMode),
                  ),
                ),
              ],
            ),

            // Admin Mode button positioned at the bottom center of the screen
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _navigateToAdminMode,
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.textLight,
                  ),
                  label: const Text(
                    'Admin Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'VarelaRound',
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                  ),
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
                // Navigate back to home
                Navigator.pop(context);
              } else if (index == 2) {
                // Navigate to Schedule screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleScreen(),
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

  Widget _buildErrorView(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontFamily: 'Switzer',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: 'VarelaRound',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshHouseholdData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHouseholdView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 80,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Household Selected',
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
            'Create a new household or join an existing one',
            style: TextStyle(
              fontSize: 14,
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
              fontFamily: 'VarelaRound',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateHouseholdDialog,
                icon: Icon(Icons.add_home, color: AppColors.textLight),
                label: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showJoinHouseholdDialog,
                icon: Icon(Icons.group_add, color: AppColors.textLight),
                label: const Text('Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New method to show options dialog
  void _showCreateOrJoinOptionsDialog() {
    // Use Provider with listen: false
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(
            'Household Options',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              isDarkMode ? AppColors.surfaceDark : AppColors.surface,
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showCreateHouseholdDialog();
              },
              child: ListTile(
                leading: Icon(
                  Icons.add_home,
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                ),
                title: Text(
                  'Create New Household',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showJoinHouseholdDialog();
              },
              child: ListTile(
                leading: Icon(
                  Icons.group_add,
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                ),
                title: Text(
                  'Join Existing Household',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                ),
                title: Text(
                  'Cancel',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // New method to show options when no household is selected
  void _showNoHouseholdOptionsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No household selected. Create or join a household first.',
        ),
      ),
    );

    _showCreateOrJoinOptionsDialog();
  }

  // This widget displays both the member list and the add flatmates content
  Widget _buildMembersListWithAddContent(bool isDarkMode) {
    // Only show admin users first
    final adminMembers = _members.where((m) => m.role == 'admin').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Display admin members at the top
        ...adminMembers.map((member) => _buildMemberCard(member, isDarkMode)),

        // Other members if there are any
        if (_members.length > adminMembers.length)
          ..._members
              .where((m) => m.role != 'admin')
              .map((member) => _buildMemberCard(member, isDarkMode)),

        // Add the "Add your flatmates" section if admin is the only member
        if (_members.length <= 1) _buildAddFlatmatesSection(isDarkMode),

        // Add some space at the bottom for the Admin Mode button
        const SizedBox(height: 60),
      ],
    );
  }

  // Section for "Add your flatmates" with SVG and text
  Widget _buildAddFlatmatesSection(bool isDarkMode) {
    return Column(
      children: [
        const SizedBox(height: 10), // Reduced top spacing
        // SVG image of people moving boxes - smaller height
        SvgPicture.asset(
          'assets/images/no_members.svg', // Adjust path as needed
          height: 270, // Reduced from 392 to make it smaller
          // Removed color filter so SVG appears the same in both light and dark mode
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10), // Reduced spacing between SVG and text
        Text(
          'Add your Flatmates by sharing',
          style: TextStyle(
            fontSize: 18, // Slightly smaller font
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
            fontFamily: 'VarelaRound',
          ),
        ),
        Text(
          'room code through socials',
          style: TextStyle(
            fontSize: 18, // Slightly smaller font
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
            fontFamily: 'VarelaRound',
          ),
        ),
        const SizedBox(height: 20), // Reduced bottom spacing
      ],
    );
  }

  Widget _buildMemberCard(HouseholdMemberModel member, bool isDarkMode) {
    // Determine role badge color
    Color roleBadgeColor = AppColors.primary;
    if (member.role == 'admin') {
      roleBadgeColor = AppColors.primary;
    }

    // Determine if email needs to be truncated
    final email = member.email ?? 'No email';
    final displayEmail =
        email.length > 20 ? '${email.substring(0, 20)}...' : email;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 24,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            backgroundImage:
                member.profileImageUrl != null &&
                        member.profileImageUrl!.isNotEmpty
                    ? _getProfileImage(member.profileImageUrl!)
                    : null,
            child:
                member.profileImageUrl == null ||
                        member.profileImageUrl!.isEmpty
                    ? Text(
                      _getInitials(member.fullName ?? member.email ?? 'User'),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Switzer',
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  style: TextStyle(
                    fontSize: 13, // Reduced font size for email
                    fontFamily: 'VarelaRound',
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if text overflows
                ),
              ],
            ),
          ),

          // Role badge with reduced right margin
          Container(
            margin: const EdgeInsets.only(right: 4), // Reduced from 6
            padding: const EdgeInsets.symmetric(
              horizontal: 10, // Reduced from 12
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: roleBadgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'VarelaRound',
                color: AppColors.textLight,
              ),
            ),
          ),

          // Edit icon - reduced size and padding
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/icons/pencil.svg',
              height: 16, // Reduced from 18
              width: 16, // Reduced from 18
              colorFilter: ColorFilter.mode(
                isDarkMode ? AppColors.primaryDark : AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              _showEditMemberDialog(member);
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Helper method to manage profile image loading
  ImageProvider? _getProfileImage(String url) {
    try {
      // Check if the URL is valid
      if (url.startsWith('http')) {
        return NetworkImage(url);
      } else {
        print('Invalid image URL format: $url');
        return null;
      }
    } catch (e) {
      print('Error loading profile image: $e');
      return null;
    }
  }

  // Helper to check if current user is admin
  bool _canEditMember() {
    // For now, assume the user can edit members
    // You might need to implement proper role checking
    return true;
  }

  // Helper to get initials from a name
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else {
      return name.isNotEmpty ? name[0].toUpperCase() : '?';
    }
  }

  // Capitalize the first letter of role
  String _capitalizeRole(String role) {
    if (role.isEmpty) return role;
    return role[0].toUpperCase() + role.substring(1);
  }
}
