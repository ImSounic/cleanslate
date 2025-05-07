import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';

class HouseholdDetailScreen extends StatefulWidget {
  final String householdId;

  const HouseholdDetailScreen({Key? key, required this.householdId})
    : super(key: key);

  @override
  State<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends State<HouseholdDetailScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final ChoreRepository _choreRepository = ChoreRepository();
  Map<String, dynamic>? _household;
  List<Map<String, dynamic>> _chores = [];
  bool _isLoading = true;

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

      setState(() {
        _household = household;
        _chores = chores;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to create a new chore
        },
        child: const Icon(Icons.add_task),
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
          ElevatedButton.icon(
            onPressed: () {
              // Show dialog to create a new chore
            },
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
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to chore detail/assignment screen
            },
          ),
        );
      },
    );
  }

  Widget _buildMembersList() {
    final members = (_household?['household_members'] as List?) ?? [];

    return ListView.builder(
      itemCount: members.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              member['user_id'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(member['role']),
            ),
          ),
        );
      },
    );
  }
}
