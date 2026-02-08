// lib/features/home/widgets/create_household_dialog.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/core/utils/input_sanitizer.dart';
import 'package:cleanslate/core/services/error_service.dart';
import 'package:cleanslate/features/household/screens/initial_room_setup_screen.dart';

class CreateHouseholdDialog extends StatefulWidget {
  const CreateHouseholdDialog({super.key});

  @override
  State<CreateHouseholdDialog> createState() => _CreateHouseholdDialogState();
}

class _CreateHouseholdDialogState extends State<CreateHouseholdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _householdService = HouseholdService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final household = await _householdService.createAndSetHousehold(
        sanitizeHouseholdName(_nameController.text),
      );
      if (mounted) {
        // Close the dialog first
        Navigator.of(context).pop();
        
        // Navigate to room setup screen
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => InitialRoomSetupScreen(household: household),
          ),
        );
        
        // If user completed setup, we need to signal success
        if (result == true && context.mounted) {
          // Pop again or signal the parent - the household is now set up
          // The parent will rebuild with the new household
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'createHousehold');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Household',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Switzer',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Household Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a household name';
                  }
                  if (value.trim().length > 100) {
                    return 'Household name must be 100 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text('Create', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
