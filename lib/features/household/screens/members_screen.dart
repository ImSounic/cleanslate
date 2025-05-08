// lib/features/household/screens/members_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _householdRepository.getHouseholds();
      setState(() {
        _members = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading households: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Households')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _members.isEmpty
              ? _buildEmptyState()
              : _buildMembersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateHouseholdDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No households yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first household to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateHouseholdDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Household'),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                member['name'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Member since ${member['joinDate']}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle member tap
            },
          ),
        );
      },
    );
  }

  Future<void> _showCreateHouseholdDialog() async {
    final nameController = TextEditingController();
    bool isCreating = false;

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Create Household'),
                  content: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Household Name',
                      hintText: 'Enter a name for your household',
                    ),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isCreating
                              ? null
                              : () async {
                                if (nameController.text.trim().isEmpty) {
                                  return;
                                }

                                setState(() {
                                  isCreating = true;
                                });

                                try {
                                  await _householdRepository.createHousehold(
                                    nameController.text.trim(),
                                  );

                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    _loadMembers();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isCreating = false;
                                    });
                                  }
                                }
                              },
                      child:
                          isCreating
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }
}
