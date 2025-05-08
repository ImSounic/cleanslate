// lib/features/members/screens/members_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/settings/screens/settings_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final HouseholdService _householdService = HouseholdService();
  int _selectedNavIndex = 1; // Members tab selected

  List<HouseholdMemberModel> _members = [];
  bool _isLoading = true;
  String _householdName = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current household
      final currentHousehold = _householdService.currentHousehold;
      if (currentHousehold == null) {
        // Handle case when no household is selected
        setState(() {
          _isLoading = false;
          _householdName = 'No Household Selected';
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

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading members: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button, search bar and code button section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.primary),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'VarelaRound',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for members',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'VarelaRound',
                            fontSize: 14,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                          isDense: true,
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
                      'Show Code',
                      style: TextStyle(fontFamily: 'VarelaRound', fontSize: 14),
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
                      fontSize: 28,
                      fontFamily: 'Switzer',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _householdName,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'VarelaRound',
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Members list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _members.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          return _buildMemberCard(_members[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            if (index != _selectedNavIndex) {
              // Navigate back to home if home icon is clicked
              if (index == 0) {
                Navigator.pop(context);
              } else if (index == 3) {
                // Settings tab
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
              // Handle other navigation items here
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No members found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite some people to join your household',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_householdService.currentHousehold != null) {
                _showHouseholdCode(_householdService.currentHousehold!.code);
              }
            },
            icon: Icon(Icons.share, color: AppColors.textLight),
            label: const Text('Share Invite Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(HouseholdMemberModel member) {
    // Determine role badge color
    Color roleBadgeColor = AppColors.primary;
    if (member.role == 'admin') {
      roleBadgeColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                member.profileImageUrl != null
                    ? NetworkImage(member.profileImageUrl!)
                    : null,
            child:
                member.profileImageUrl == null
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
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'VarelaRound',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleBadgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _capitalizeRole(member.role),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'VarelaRound',
                color: AppColors.textLight,
              ),
            ),
          ),

          // Edit icon - only show for admins
          if (_canEditMember())
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/icons/pencil.svg',
                height: 18,
                width: 18,
                colorFilter: ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                _showEditMemberDialog(member);
              },
            ),
        ],
      ),
    );
  }

  // Helper to check if current user is admin
  bool _canEditMember() {
    // You might need to check if the current user is an admin of the household
    // For simplicity, let's assume they can edit
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

  // Show household code dialog
  void _showHouseholdCode(String code) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Household Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share this code with others to invite them to your household:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
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
          ),
    );
  }

  // Show edit member dialog
  void _showEditMemberDialog(HouseholdMemberModel member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${member.fullName ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Email: ${member.email ?? 'N/A'}'),
                const SizedBox(height: 16),
                const Text('Role:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: member.role,
                  isExpanded: true,
                  items:
                      ['member', 'admin'].map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(_capitalizeRole(role)),
                        );
                      }).toList(),
                  onChanged: (String? newRole) {
                    if (newRole != null) {
                      Navigator.pop(context);
                      _updateMemberRole(member.id, newRole);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(member);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Remove Member'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    try {
      await _householdRepository.updateMemberRole(memberId, newRole);
      // Refresh members list
      _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member role updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating member role: $e')),
        );
      }
    }
  }

  void _confirmRemoveMember(HouseholdMemberModel member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${member.fullName ?? 'this member'} from the household?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeMember(member.id);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await _householdRepository.removeMemberFromHousehold(memberId);
      // Refresh members list
      _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
      }
    }
  }
}
