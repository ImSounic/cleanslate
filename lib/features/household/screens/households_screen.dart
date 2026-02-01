// lib/features/household/screens/households_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/features/household/screens/household_detail_screen.dart'; // Add this import
import 'package:cleanslate/core/services/error_service.dart';

class HouseholdsScreen extends StatefulWidget {
  const HouseholdsScreen({super.key});

  @override
  State<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends State<HouseholdsScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  List<Map<String, dynamic>> _households = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final households = await _householdRepository.getHouseholds();
      setState(() {
        _households = households;
      });
    } catch (e) {
      if (!mounted) return;
      ErrorService.showError(context, e, operation: 'loadHouseholds');
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
              : _households.isEmpty
              ? _buildEmptyState()
              : _buildHouseholdsList(),
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

  Widget _buildHouseholdsList() {
    return ListView.builder(
      itemCount: _households.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final household = _households[index];
        final memberCount = (household['household_members'] as List).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                household['name'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              household['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('$memberCount members'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to household detail screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          HouseholdDetailScreen(householdId: household['id']),
                ),
              );
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
                                    _loadHouseholds();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ErrorService.showError(context, e, operation: 'createHousehold');
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
