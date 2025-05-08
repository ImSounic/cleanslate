// lib/features/members/screens/admin_mode_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';

class AdminModeScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const AdminModeScreen({Key? key}) : super(key: key);

  @override
  State<AdminModeScreen> createState() => _AdminModeScreenState();
}

class _AdminModeScreenState extends State<AdminModeScreen> {
  final HouseholdService _householdService = HouseholdService();
  final TextEditingController _deleteConfirmController =
      TextEditingController();
  int _selectedNavIndex = 1; // Members tab selected

  // Sample data for the UI demo - in a real app this would come from your repository
  final List<Map<String, dynamic>> _joinRequests = [
    {
      'id': '1',
      'name': 'Alice Johnson',
      'profileImage': 'assets/images/profile_pictures/alice.png',
    },
    {
      'id': '2',
      'name': 'Jamie',
      'profileImage': 'assets/images/profile_pictures/jamie.png',
    },
    {
      'id': '3',
      'name': 'Donnie',
      'profileImage': 'assets/images/profile_pictures/donnie.png',
    },
  ];

  final List<Map<String, dynamic>> _memberStats = [
    {
      'id': '1',
      'name': 'Eva White',
      'profileImage': 'assets/images/profile_pictures/eva.png',
      'choresCompleted': 9,
      'choresAssigned': 12,
    },
    {
      'id': '2',
      'name': 'Jane Cooper',
      'profileImage': 'assets/images/profile_pictures/jane.png',
      'choresCompleted': 37,
      'choresAssigned': 4,
    },
    {
      'id': '3',
      'name': 'Jacob Jones',
      'profileImage': 'assets/images/profile_pictures/jacob.png',
      'choresCompleted': 48,
      'choresAssigned': 12,
    },
    {
      'id': '4',
      'name': 'Robert Fox',
      'profileImage': 'assets/images/profile_pictures/robert.png',
      'choresCompleted': 37,
      'choresAssigned': 4,
    },
  ];

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
                    // Handle transfer ownership
                    Navigator.of(context).pop();
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

  void _showDeleteConfirmation() {
    _deleteConfirmController.clear();
    final currentHousehold = _householdService.currentHousehold;
    final householdName = currentHousehold?.name ?? 'Household';

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
                        onPressed: () {
                          if (_deleteConfirmController.text.trim() ==
                              householdName) {
                            // Delete the household
                            Navigator.of(context).pop();
                            Navigator.of(
                              context,
                            ).pop(); // Go back to members screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Household deleted'),
                              ),
                            );
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

  void _handleRequestAction(String requestId, bool isApproved) {
    // Here you would typically call your repository to accept/reject the request
    // For now, just remove it from the UI list
    setState(() {
      _joinRequests.removeWhere((request) => request['id'] == requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApproved ? 'Request approved' : 'Request rejected'),
      ),
    );
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
        case 2: // Calendar - would implement if you have a CalendarScreen
          Navigator.pop(context); // For now, just go back to members screen
          // In a real app: Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
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
    // Removed unused variable 'householdName'

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
        child: Column(
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
                  const Text(
                    'Manage those requests like\nyou manage those chores.',
                    style: TextStyle(
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
                    // Join Requests Section
                    if (_joinRequests.isNotEmpty)
                      ..._joinRequests.map(
                        (request) => _buildRequestCard(request),
                      ),

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
                              'Manage',
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

                    // Member Statistics - Using ListView instead of GridView
                    Padding(
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
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation, // Use the navigation handler
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary, // Match the background color
        selectedItemColor: const Color(
          0xFFF4F3EE,
        ), // The requested color for icons
        unselectedItemColor: const Color(
          0xFFF4F3EE,
        ).withOpacity(0.6), // Lighter version for unselected
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
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
          backgroundImage: AssetImage(request['profileImage']),
          radius: 24,
        ),
        title: Text(
          request['name'] == 'Alice Johnson'
              ? '${request['name']} is requesting to join your household'
              : '${request['name']} is requesting to join your household',
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
                decoration: BoxDecoration(
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
                decoration: BoxDecoration(
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
    // Using a fixed height container to prevent overflow
    return Container(
      height: 170, // Significantly increased height
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
                  member['name'],
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
                backgroundImage: AssetImage(member['profileImage']),
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chores completed
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chores completed in household',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'VarelaRound',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, color: Colors.yellow, size: 16),
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
            children: [
              Expanded(
                child: Text(
                  'Chores assigned in household',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'VarelaRound',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.assignment_ind, color: Colors.white, size: 16),
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
}
