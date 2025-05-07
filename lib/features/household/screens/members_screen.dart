// lib/features/household/screens/members_screen.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';

class MembersScreen extends StatefulWidget {
  final String householdId;
  final String householdName;

  const MembersScreen({
    Key? key,
    required this.householdId,
    required this.householdName,
  }) : super(key: key);

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
      // In a real app, you would fetch this from your repository
      // For now, we'll use example data
      setState(() {
        _members = [
          {
            'id': '1',
            'name': 'You',
            'email': 'Email@gmail.com',
            'relationship': 'Relation',
          },
          {
            'id': '2',
            'name': 'Alice Johnson',
            'email': 'alice.johnson@example.com',
            'relationship': 'Friend',
          },
          {
            'id': '3',
            'name': 'Bob Smith',
            'email': 'bob.smith@example.com',
            'relationship': 'Colleague',
          },
          {
            'id': '4',
            'name': 'Catherine Lee',
            'email': 'catherine.lee@example.com',
            'relationship': 'Sister',
          },
          {
            'id': '5',
            'name': 'David Brown',
            'email': 'david.brown@example.com',
            'relationship': 'Cousin',
          },
          {
            'id': '6',
            'name': 'Eva White',
            'email': 'eva.white@example.com',
            'relationship': 'Acquaintance',
          },
        ];
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A63B9),
                    ),
                  ),
                  Text(
                    'The ${widget.householdName}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return _buildMemberCard(member, index);
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Members tab
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A63B9),
        unselectedItemColor: Colors.grey,
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

  Widget _buildMemberCard(Map<String, dynamic> member, int index) {
    final colors = [
      Colors.pink.shade100,
      Colors.purple.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
    ];

    final color = colors[index % colors.length];
    final initial = index == 0 ? 'M' : (index).toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Member details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      member['email'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Relationship chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A63B9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  member['relationship'],
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              // Edit icon
              Icon(Icons.edit, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
