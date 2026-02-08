// lib/features/home/widgets/join_household_dialog.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/members/screens/qr_scanner_screen.dart';
import 'package:cleanslate/core/utils/input_sanitizer.dart';
import 'package:cleanslate/core/services/error_service.dart';

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
        sanitizeSingleLine(_codeController.text, maxLength: 8),
      );

      // Set the newly joined household as current
      _householdService.setCurrentHousehold(household);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'joinHousehold');
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
                  final trimmed = value.trim().toUpperCase();
                  if (trimmed.length != 8) {
                    return 'Code must be exactly 8 characters';
                  }
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmed)) {
                    return 'Code can only contain letters and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final scannedCode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerScreen(),
                      ),
                    );

                    if (scannedCode != null && mounted) {
                      _codeController.text = scannedCode;
                      // Auto-submit if the scanned code is valid (8 characters)
                      if (scannedCode.length == 8) {
                        _handleJoin();
                      }
                    }
                  },
                  icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  label: Text(
                    'Scan QR Code Instead',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ),
              ),
              // Show scanning indicator when loading after QR scan
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Joining household...',
                        style: TextStyle(
                          fontFamily: 'VarelaRound',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
