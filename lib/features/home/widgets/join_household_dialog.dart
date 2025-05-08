// lib/features/home/widgets/join_household_dialog.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';

class JoinHouseholdDialog extends StatefulWidget {
  const JoinHouseholdDialog({super.key});

  @override
  State<JoinHouseholdDialog> createState() => _JoinHouseholdDialogState();
}

class _JoinHouseholdDialogState extends State<JoinHouseholdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _householdRepository = HouseholdRepository();
  final _householdService = HouseholdService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final household = await _householdRepository.joinHouseholdWithCode(
        _codeController.text.trim(),
      );

      // Set the newly joined household as current
      _householdService.setCurrentHousehold(household);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
                'Join Household',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Switzer',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the household code shared with you',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'VarelaRound',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Household Code',
                  hintText: 'Enter 8-character code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: Icon(Icons.key, color: AppColors.primary),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a household code';
                  }
                  if (value.length != 8) {
                    return 'Code must be 8 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleJoin,
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
                        : const Text('Join', style: TextStyle(fontSize: 16)),
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
