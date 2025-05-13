// lib/features/household/screens/household_detail_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/models/household_member_model.dart';

class HouseholdDetailScreen extends StatefulWidget {
  final String householdId;

  const HouseholdDetailScreen({super.key, required this.householdId});

  @override
  State<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends State<HouseholdDetailScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final ChoreRepository _choreRepository = ChoreRepository();
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, dynamic>? _household;
  List<Map<String, dynamic>> _chores = [];
  List<HouseholdMemberModel> _members = [];
  bool _isLoading = true;
  bool _isCurrentUserAdmin = false; // Track if current user is admin

  @override
  void initState() {
    super.initState();
    _loadHouseholdData();
  }

  Future<void> _loadHouseholdData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final household = await _householdRepository.getHousehold(
        widget.householdId,
      );
      final chores = await _choreRepository.getChoresForHousehold(
        widget.householdId,
      );

      // Get household members
      final members = await _householdRepository.getHouseholdMembers(
        widget.householdId,
      );

      // Check if current user is admin
      final currentUserId = _supabaseService.currentUser?.id;
      final isAdmin = members.any(
        (member) => member.userId == currentUserId && member.role == 'admin',
      );

      setState(() {
        _household = household;
        _chores = chores;
        _members = members;
        _isCurrentUserAdmin = isAdmin;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading household: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_household?['name'] ?? 'Household')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildHouseholdDetail(),
      // Only show FAB if the user is admin
      floatingActionButton:
          _isCurrentUserAdmin
              ? FloatingActionButton(
                onPressed: () {
                  // Show dialog to create a new chore
                  _showAddChoreDialog();
                },
                child: const Icon(Icons.add_task),
              )
              : null,
    );
  }

  void _showAddChoreDialog() {
    // Make sure user is admin
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can add chores')),
      );
      return;
    }

    // Show dialog for adding a chore
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Chore'),
            content: const Text('Add chore dialog will be implemented here'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Add chore logic will go here
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Widget _buildHouseholdDetail() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: const [Tab(text: 'Chores'), Tab(text: 'Members')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Chores tab
                _chores.isEmpty ? _buildEmptyChoresState() : _buildChoresList(),

                // Members tab
                _buildMembersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChoresState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No chores yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add chores to start assigning tasks',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Only show add button if user is admin
          if (_isCurrentUserAdmin)
            ElevatedButton.icon(
              onPressed: _showAddChoreDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Chore'),
            ),
        ],
      ),
    );
  }

  Widget _buildChoresList() {
    return ListView.builder(
      itemCount: _chores.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final chore = _chores[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.cleaning_services, color: Colors.white),
            ),
            title: Text(
              chore['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle:
                chore['description'] != null
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(chore['description']),
                    )
                    : null,
            trailing:
                _isCurrentUserAdmin
                    ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showChoreOptions(chore),
                    )
                    : const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to chore detail/assignment screen
              _viewChoreDetails(chore);
            },
          ),
        );
      },
    );
  }

  void _showChoreOptions(Map<String, dynamic> chore) {
    // Only admin can edit chores
    if (!_isCurrentUserAdmin) {
      _viewChoreDetails(chore);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Chore'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit chore
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Chore',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChore(chore['id']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_ind),
                title: const Text('Assign to Member'),
                onTap: () {
                  Navigator.pop(context);
                  // Show assignment dialog
                },
              ),
            ],
          ),
    );
  }

  void _viewChoreDetails(Map<String, dynamic> chore) {
    // Show chore details
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(chore['name']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chore['description'] != null) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(chore['description']),
                  const SizedBox(height: 8),
                ],
                // Add other chore details here
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteChore(String choreId) {
    // Only admin can delete chores
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can delete chores')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Chore'),
            content: const Text(
              'Are you sure you want to delete this chore? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _choreRepository.deleteChore(choreId);
                    await _loadHouseholdData(); // Refresh the data
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chore deleted successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting chore: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      itemCount: _members.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isCurrentUser = member.userId == _supabaseService.currentUser?.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage:
                  member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
              child:
                  member.profileImageUrl == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
            ),
            title: Text(
              member.fullName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                member.role == 'admin' ? 'Admin' : 'Member',
                style: TextStyle(
                  color: member.role == 'admin' ? Colors.orange : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Show edit/options button if admin or it's the current user
            trailing:
                (_isCurrentUserAdmin || isCurrentUser)
                    ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showMemberOptions(member),
                    )
                    : null,
          ),
        );
      },
    );
  }

  void _showMemberOptions(HouseholdMemberModel member) {
    final isCurrentUser = member.userId == _supabaseService.currentUser?.id;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // If admin, show option to change role
              if (_isCurrentUserAdmin && !isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(
                    member.role == 'admin' ? 'Remove Admin Role' : 'Make Admin',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _updateMemberRole(
                      member.id,
                      member.role == 'admin' ? 'member' : 'admin',
                    );
                  },
                ),

              // If admin, show option to remove member
              if (_isCurrentUserAdmin && !isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text(
                    'Remove from Household',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRemoveMember(member);
                  },
                ),

              // If it's the current user, show option to leave
              if (isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text(
                    'Leave Household',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLeaveHousehold();
                  },
                ),

              // Close button
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    // Only admin can change roles
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can change member roles')),
      );
      return;
    }

    try {
      await _householdRepository.updateMemberRole(memberId, newRole);
      await _loadHouseholdData(); // Refresh the data
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
    // Only admin can remove members
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can remove members')),
      );
      return;
    }

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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _householdRepository.removeMemberFromHousehold(
                      member.id,
                    );
                    await _loadHouseholdData(); // Refresh the data
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Member removed successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error removing member: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _confirmLeaveHousehold() {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return;

    // Find the current user's member record
    final currentMember = _members.firstWhere(
      (member) => member.userId == currentUserId,
      orElse: () => throw Exception('Member not found'),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Household'),
            content: const Text(
              'Are you sure you want to leave this household? You will need an invite code to rejoin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _householdRepository.removeMemberFromHousehold(
                      currentMember.id,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have left the household'),
                        ),
                      );
                      // Navigate back to previous screen
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error leaving household: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }
}
