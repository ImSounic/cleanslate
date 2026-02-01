// lib/features/chores/screens/edit_chore_screen.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cleanslate/core/utils/input_sanitizer.dart';

/// Screen for editing an existing chore's details.
class EditChoreScreen extends StatefulWidget {
  final Map<String, dynamic> chore;
  final Map<String, dynamic> assignment;

  const EditChoreScreen({
    super.key,
    required this.chore,
    required this.assignment,
  });

  @override
  State<EditChoreScreen> createState() => _EditChoreScreenState();
}

class _EditChoreScreenState extends State<EditChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  final _choreRepository = ChoreRepository();

  late String _priority;
  late DateTime _dueDate;
  TimeOfDay? _dueTime;
  bool _isSaving = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    final chore = widget.chore;
    final assignment = widget.assignment;

    _titleController = TextEditingController(text: chore['name'] ?? '');
    _descriptionController =
        TextEditingController(text: chore['description'] ?? '');

    _priority = _capitalize(
      (assignment['priority'] ?? 'medium').toString(),
    );

    if (assignment['due_date'] != null) {
      final dt = DateTime.parse(assignment['due_date']);
      _dueDate = dt;
      if (dt.hour != 0 || dt.minute != 0) {
        _dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    } else {
      _dueDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Build due date with time
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

      final sanitizedName = sanitizeChoreName(_titleController.text);
      final sanitizedDesc = sanitizeDescription(_descriptionController.text);

      // Update the chore itself (name, description)
      await _choreRepository.updateChore(
        choreId: widget.chore['id'],
        name: sanitizedName,
        description: sanitizedDesc,
      );

      // Update the assignment (due date, priority)
      await _choreRepository.updateChoreAssignment(
        assignmentId: widget.assignment['id'],
        dueDate: dueDateTime,
        priority: _priority.toLowerCase(),
      );

      if (mounted) {
        Navigator.pop(context, true); // true = changed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chore updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating chore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _selectDate() async {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              onPrimary: Colors.white,
              surface: isDarkMode ? AppColors.surfaceDark : Colors.white,
              onSurface: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor:
                  isDarkMode ? AppColors.backgroundDark : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (mounted && picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              onPrimary: Colors.white,
              surface: isDarkMode ? AppColors.surfaceDark : Colors.white,
              onSurface: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor:
                  isDarkMode ? AppColors.backgroundDark : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (mounted && picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : const Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : const Color(0xFFF4F3EE),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Chore',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildLabel('Chore Title', isDarkMode),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Buy groceries', isDarkMode),
                style: _inputTextStyle(isDarkMode),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel('Description', isDarkMode),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    _inputDecoration('Add details about the chore', isDarkMode),
                maxLines: 4,
                style: _inputTextStyle(isDarkMode),
              ),
              const SizedBox(height: 20),

              // Priority
              _buildLabel('Priority', isDarkMode),
              _buildDropdownContainer(
                isDarkMode: isDarkMode,
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor:
                      isDarkMode ? AppColors.surfaceDark : Colors.white,
                  value: _priority,
                  items: _priorities.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 20,
                            color: p == 'Low'
                                ? AppColors.priorityLow
                                : p == 'Medium'
                                    ? AppColors.priorityMedium
                                    : AppColors.priorityHigh,
                          ),
                          const SizedBox(width: 8),
                          Text(p, style: _inputTextStyle(isDarkMode)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Due Date
              _buildLabel('Due Date', isDarkMode),
              _buildTapContainer(
                isDarkMode: isDarkMode,
                onTap: _selectDate,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(_formatDate(_dueDate),
                        style: _inputTextStyle(isDarkMode)),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Due Time
              _buildLabel('Due Time', isDarkMode),
              _buildTapContainer(
                isDarkMode: isDarkMode,
                onTap: _selectTime,
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _dueTime == null ? 'Set time' : _dueTime!.format(context),
                      style: _inputTextStyle(isDarkMode),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: (isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary)
                        .withValues(alpha: 0.5),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
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

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _buildLabel(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'VarelaRound',
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDarkMode) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      hintStyle: TextStyle(
        color: isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  TextStyle _inputTextStyle(bool isDarkMode) {
    return TextStyle(
      color:
          isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );
  }

  Widget _buildDropdownContainer({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildTapContainer({
    required bool isDarkMode,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
