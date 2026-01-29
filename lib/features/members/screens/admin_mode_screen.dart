// lib/features/members/screens/admin_mode_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

class AdminModeScreen extends StatefulWidget {
  const AdminModeScreen({super.key});

  @override
  State<AdminModeScreen> createState() => _AdminModeScreenState();
}

class _AdminModeScreenState extends State<AdminModeScreen> {
  final HouseholdService _householdService = HouseholdService();
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final ChoreRepository _choreRepository = ChoreRepository();
  final TextEditingController _deleteConfirmController =
      TextEditingController();

  int _selectedNavIndex = 1; // Members tab selected
  bool _isLoading = true;
  String _errorMessage = '';

  // Store real data
  List<Map<String, dynamic>> _joinRequests = [];
  List<Map<String, dynamic>> _memberStats = [];
  String _householdName = '';
  String _householdCode = '';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current household
      final currentHousehold = _householdService.currentHousehold;
      if (currentHousehold == null) {
        setState(() {
          _errorMessage = 'No household selected';
          _isLoading = false;
        });
        return;
      }

      // Set household name and code
      _householdName = currentHousehold.name;
      _householdCode = currentHousehold.code;

      // Load household members
      final members = await _householdRepository.getHouseholdMembers(
        currentHousehold.id,
      );

      // Load pending join requests
      // Note: In a real app, you would have a separate table for join requests
      // For now, we're leaving this empty as there's no join request table in your data model
      // This would be implemented once you add that functionality to your backend
      _joinRequests = [];

      // Calculate member statistics
      await _calculateMemberStats(members, currentHousehold.id);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateMemberStats(
    List<HouseholdMemberModel> members,
    String householdId,
  ) async {
    _memberStats = [];

    try {
      // Get all chores for the household
      final chores = await _choreRepository.getChoresForHousehold(householdId);

      // Create stats for each member
      for (var member in members) {
        // Count completed and assigned chores for this member
        int choresCompleted = 0;
        int choresAssigned = 0;

        for (var chore in chores) {
          final assignments = chore['chore_assignments'] as List? ?? [];

          for (var assignment in assignments) {
            if (assignment['assigned_to'] == member.userId) {
              choresAssigned++;

              if (assignment['status'] == 'completed') {
                choresCompleted++;
              }
            }
          }
        }

        // Add member stats
        _memberStats.add({
          'id': member.userId,
          'name': member.fullName ?? member.email ?? 'User',
          'email': member.email ?? '',
          'profileImageUrl': member.profileImageUrl,
          'role': member.role,
          'choresCompleted': choresCompleted,
          'choresAssigned': choresAssigned,
        });
      }

      // Sort by chores completed (highest first)
      _memberStats.sort(
        (a, b) => b['choresCompleted'].compareTo(a['choresCompleted']),
      );
    } catch (e) {
      debugLog('Error calculating member stats: $e');
      // Still maintain the basic member list even if chore stats fail
      for (var member in members) {
        _memberStats.add({
          'id': member.userId,
          'name': member.fullName ?? member.email ?? 'User',
          'email': member.email ?? '',
          'profileImageUrl': member.profileImageUrl,
          'role': member.role,
          'choresCompleted': 0,
          'choresAssigned': 0,
        });
      }
    }
  }

  void _showOptionsOverlay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),

                // Quit Admin Mode option
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Close overlay
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Text(
                          'Quit Admin Mode',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transfer Ownership option
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showTransferOwnershipDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Text(
                          'Transfer Ownership',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Share Household Code
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showHouseholdCodeDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Text(
                          'Share Household Code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete Household option
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 16),
                        Text(
                          'Delete household',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
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

  void _showHouseholdCodeDialog() {
    final code = _householdCode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Household Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this code with others to invite them to your household:',
                textAlign: TextAlign.center,
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
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.copy, color: AppColors.primary, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to copy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferOwnershipDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Filter members who are not admins
        final eligibleMembers =
            _memberStats.where((member) => member['role'] != 'admin').toList();

        if (eligibleMembers.isEmpty) {
          return AlertDialog(
            title: const Text('Transfer Ownership'),
            content: const Text(
              'There are no other members to transfer ownership to. Invite more members first.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        }

        String? selectedMemberId;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Transfer Ownership'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a member to transfer household ownership to:',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select a member'),
                        value: selectedMemberId,
                        items:
                            eligibleMembers.map((member) {
                              return DropdownMenuItem<String>(
                                value: member['id'],
                                child: Text(member['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMemberId = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Warning: This will give admin privileges to the selected member and you will no longer be the owner.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedMemberId == null
                          ? null
                          : () async {
                            Navigator.pop(context);
                            await _transferOwnership(selectedMemberId!);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // This would typically be implemented in your backend
      // For now, simulate updating member roles
      await _householdRepository.updateMemberRole(newOwnerId, 'admin');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ownership transferred successfully')),
      );

      // Reload data
      await _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to transfer ownership: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    _deleteConfirmController.clear();
    final householdName = _householdName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 16),

                // Warning icon and message
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    Text(
                      ' This action is irreversible ',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Please type your exact\nhousehold name below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontFamily: 'VarelaRound',
                  ),
                ),

                const SizedBox(height: 16),

                // Confirmation input field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _deleteConfirmController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_deleteConfirmController.text.trim() ==
                              householdName) {
                            // Delete the household
                            Navigator.of(context).pop();
                            await _deleteHousehold();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Names do not match'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteHousehold() async {
    final currentHousehold = _householdService.currentHousehold;
    if (currentHousehold == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _householdRepository.deleteHousehold(currentHousehold.id);

      // Clear current household in service
      _householdService.clearCurrentHousehold();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household deleted successfully')),
      );

      // Navigate back to members screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete household: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting household: $e')));
    }
  }

  Future<void> _handleRequestAction(String requestId, bool isApproved) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // This would typically call a method to accept/reject the request
      // For now, simulate by removing from the local list
      setState(() {
        _joinRequests.removeWhere((request) => request['id'] == requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApproved ? 'Request approved' : 'Request rejected'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleNavigation(int index) {
    if (index != _selectedNavIndex) {
      setState(() {
        _selectedNavIndex = index;
      });

      // Navigate to the appropriate screen
      switch (index) {
        case 0: // Home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          break;
        case 1: // Members - already on this screen, just close admin mode
          Navigator.pop(context);
          break;
        case 2: // Calendar
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleScreen()),
          );
          break;
        case 3: // Settings
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showOptionsOverlay,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation, // Use the navigation handler
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/icons/home.svg',
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                _selectedNavIndex == 0
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
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
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
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
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
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
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                BlendMode.srcIn,
              ),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Switzer',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontFamily: 'VarelaRound',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAdminData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Mode',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Switzer',
                ),
              ),
              Text(
                'Manage household: $_householdName',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ],
          ),
        ),

        // Join Requests
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Join Requests Section (if any)
                if (_joinRequests.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Join Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._joinRequests.map((request) => _buildRequestCard(request)),
                ],

                // Manage section with stats
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Member Statistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Member Statistics
                _memberStats.isEmpty
                    ? _buildEmptyMembersState()
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_memberStats.length / 2).ceil(),
                        itemBuilder: (context, rowIndex) {
                          return Row(
                            children: [
                              // First cell in the row
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _buildMemberStatCard(
                                    _memberStats[rowIndex * 2],
                                  ),
                                ),
                              ),

                              // Second cell in the row (if it exists)
                              if (rowIndex * 2 + 1 < _memberStats.length)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: _buildMemberStatCard(
                                      _memberStats[rowIndex * 2 + 1],
                                    ),
                                  ),
                                ),
                              // Add empty space if odd number of members
                              if (rowIndex * 2 + 1 >= _memberStats.length)
                                const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMembersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No members to display',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Switzer',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your household code to invite members',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontFamily: 'VarelaRound',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showHouseholdCodeDialog,
              icon: const Icon(Icons.share),
              label: const Text('Share Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          backgroundImage:
              request['profileImageUrl'] != null
                  ? NetworkImage(request['profileImageUrl'])
                  : null,
          child:
              request['profileImageUrl'] == null
                  ? Text(
                    _getInitials(request['name']),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          "${request['name']} is requesting to join your household",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'VarelaRound',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accept button
            GestureDetector(
              onTap: () => _handleRequestAction(request['id'], true),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Reject button
            GestureDetector(
              onTap: () => _handleRequestAction(request['id'], false),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStatCard(Map<String, dynamic> member) {
    // Define avatar color based on role
    Color avatarColor =
        member['role'] == 'admin' ? Colors.orange : AppColors.avatarGreen;

    // Get just the first name for display
    String displayName = _getFirstName(member['name']);

    // Using a fixed height container to prevent overflow - increase height to accommodate two-line labels
    return Container(
      height: 195, // Increased further to fix 12px overflow
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // User name and avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  displayName, // Now showing first name only
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'VarelaRound',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                backgroundColor: avatarColor,
                backgroundImage:
                    member['profileImageUrl'] != null
                        ? NetworkImage(member['profileImageUrl'])
                        : null,
                radius: 12,
                child:
                    member['profileImageUrl'] == null
                        ? Text(
                          _getInitials(member['name']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
            ],
          ),

          // Role badge
          if (member['role'] == 'admin')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'VarelaRound',
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Chores completed
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Chores completed in household',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'VarelaRound',
                    height: 1.2,
                  ),
                  maxLines: 2, // Allow up to 2 lines
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Colors.yellow, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${member['choresCompleted']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'VarelaRound',
            ),
          ),
          const SizedBox(height: 12),

          // Chores assigned
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Chores assigned in household',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'VarelaRound',
                    height: 1.2,
                  ),
                  maxLines: 2, // Allow up to 2 lines
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.assignment_ind, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${member['choresAssigned']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'VarelaRound',
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get initials from a name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  // Helper function to get just the first name from a full name
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return '';

    List<String> nameParts = fullName.split(' ');
    return nameParts[0];
  }
}
