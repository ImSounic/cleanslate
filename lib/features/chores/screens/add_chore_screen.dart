// lib/features/chores/screens/add_chore_screen.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:intl/intl.dart';

class AddChoreScreen extends StatefulWidget {
  const AddChoreScreen({Key? key}) : super(key: key);

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _todoTextController = TextEditingController(); // Added for todo items

  final _choreRepository = ChoreRepository();
  final _householdService = HouseholdService();

  String? _selectedMemberId;
  String _priority = 'Medium';
  DateTime _dueDate = DateTime.now();
  TimeOfDay? _dueTime;
  String? _repeatPattern;

  bool _isLoading = false;
  bool _showTodoInput = false; // To toggle todo input visibility
  List<String> _todoItems = []; // To store todo items

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<Map<String, dynamic>> _members = [];
  final List<String> _repeatOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Weekdays',
    'Weekends',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _todoTextController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final currentHousehold = _householdService.currentHousehold;
    if (currentHousehold != null) {
      try {
        // Create a new instance of HouseholdRepository
        final householdRepository = HouseholdRepository();

        // Get household members using the repository
        final members = await householdRepository.getHouseholdMembers(
          currentHousehold.id,
        );

        if (mounted) {
          setState(() {
            _members.clear();
            for (var member in members) {
              _members.add({
                'id': member.userId,
                'name': member.fullName ?? member.email ?? 'User',
                'email': member.email,
              });
            }
          });
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading household members: $e')),
          );
        }
      }
    }
  }

  // Add a todo item to the list
  void _addTodoItem() {
    final todoText = _todoTextController.text.trim();
    if (todoText.isNotEmpty) {
      setState(() {
        _todoItems.add(todoText);
        _todoTextController.clear();
        _showTodoInput = false;
      });
    }
  }

  // Format the description text with todo items
  String _getFormattedDescription() {
    String description = _descriptionController.text.trim();

    // Add todo items formatted as a list
    if (_todoItems.isNotEmpty) {
      if (description.isNotEmpty) {
        description += '\n\n';
      }

      description += "To-do items:\n";
      for (int i = 0; i < _todoItems.length; i++) {
        description += "- [ ] ${_todoItems[i]}\n";
      }
    }

    return description;
  }

  Future<void> _handleAddChore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentHousehold = _householdService.currentHousehold;
      if (currentHousehold == null) {
        throw Exception('No household selected');
      }

      // Format due date with time if provided
      DateTime dueDateTime = _dueDate;
      if (_dueTime != null) {
        dueDateTime = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      }

      // Get formatted description with todo items
      final formattedDescription = _getFormattedDescription();

      // Create chore
      final chore = await _choreRepository.createChore(
        householdId: currentHousehold.id,
        name: _titleController.text.trim(),
        description: formattedDescription,
        frequency: _repeatPattern,
      );

      // If a member is selected, assign the chore to them
      if (_selectedMemberId != null) {
        await _choreRepository.assignChore(
          choreId: chore['id'],
          assignedTo: _selectedMemberId!,
          dueDate: dueDateTime,
          priority: _priority.toLowerCase(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chore added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding chore: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    if (date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day) {
      return 'Today';
    } else if (date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day + 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F3EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Chore",
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chore Title
              _buildSectionTitle('Chore Title'),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Buy groceries',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title for the chore';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText:
                            'Add details about the chore. For sub-items or steps to follow, click on the to-do icon.',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                    ),

                    // To-do items list
                    if (_todoItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Text(
                              'To-do Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_todoItems.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_box_outline_blank,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_todoItems[index])),
                                    // Delete button for to-do item
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _todoItems.removeAt(index);
                                        });
                                      },
                                      child: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    // To-do input field that appears when the user clicks the icon
                    if (_showTodoInput)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _todoTextController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter a to-do item',
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _addTodoItem(),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: _addTodoItem,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Checklist icon to add to-do items
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTodoInput = !_showTodoInput;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Click on the icon to insert to-do blocks',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
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
              const SizedBox(height: 20),

              // Assign To
              _buildSectionTitle('Assign to'),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select household member',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    value: _selectedMemberId,
                    items:
                        _members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member['id'],
                            child: Text(member['name']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMemberId = value;
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority
              _buildSectionTitle('Priority'),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _priority,
                    items:
                        _priorities.map((priority) {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color:
                                      priority == 'Low'
                                          ? AppColors.priorityLow
                                          : priority == 'Medium'
                                          ? AppColors.priorityMedium
                                          : AppColors.priorityHigh,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(priority),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Due Date
              _buildSectionTitle('Due date'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(_dueDate)),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Due Time
              _buildSectionTitle('Due Time'),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dueTime == null
                            ? 'Set time'
                            : _dueTime!.format(context),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Repeat
              _buildSectionTitle('Repeat (Optional)'),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // Fixed hint text to avoid overflow
                        Expanded(
                          child: Text(
                            'Set repeat schedule',
                            style: TextStyle(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    value: _repeatPattern,
                    items:
                        _repeatOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option.toLowerCase(),
                            child: Text(option),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _repeatPattern = value;
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Add Chore Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddChore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Add Chore',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'VarelaRound',
          color: AppColors.primary,
        ),
      ),
    );
  }
}
