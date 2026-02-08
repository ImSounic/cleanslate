// lib/features/household/screens/initial_room_setup_screen.dart
// Simplified room setup screen shown after household creation
// Just saves configuration - no chore assignment (that happens from home screen)

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/core/services/error_service.dart';

class InitialRoomSetupScreen extends StatefulWidget {
  final HouseholdModel household;

  const InitialRoomSetupScreen({super.key, required this.household});

  @override
  State<InitialRoomSetupScreen> createState() => _InitialRoomSetupScreenState();
}

class _InitialRoomSetupScreenState extends State<InitialRoomSetupScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  bool _isSaving = false;

  int _numKitchens = 1;
  int _numBathrooms = 1;
  int _numLivingRooms = 1;

  Future<void> _confirm() async {
    setState(() => _isSaving = true);

    try {
      // Save room configuration
      await _householdRepository.updateRoomConfig(
        widget.household.id,
        numKitchens: _numKitchens,
        numBathrooms: _numBathrooms,
        numLivingRooms: _numLivingRooms,
      );

      // Reload household to get updated config
      final freshHousehold = await _householdRepository.getHouseholdModel(widget.household.id);
      HouseholdService().setCurrentHousehold(freshHousehold);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'saveRoomConfig');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button - must complete setup
        title: Text(
          'Set Up Your Home',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 50,
                    color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                'Tell us about "${widget.household.name}"',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Switzer',
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us create the right chores for your household. You can change this later in Admin Mode.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'VarelaRound',
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Room counters
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildRoomCounter(
                        icon: '🍳',
                        label: 'Kitchens',
                        value: _numKitchens,
                        onChanged: (v) => setState(() => _numKitchens = v),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildRoomCounter(
                        icon: '🚿',
                        label: 'Bathrooms',
                        value: _numBathrooms,
                        onChanged: (v) => setState(() => _numBathrooms = v),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildRoomCounter(
                        icon: '🛋️',
                        label: 'Living Rooms',
                        value: _numLivingRooms,
                        onChanged: (v) => setState(() => _numLivingRooms = v),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Once members join, you can assign chores from the home screen.',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'VarelaRound',
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCounter({
    required String icon,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'VarelaRound',
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          // Counter controls
          Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  icon: Icon(
                    Icons.remove_rounded,
                    color: value > 0
                        ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  ),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Switzer',
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: value < 10 ? () => onChanged(value + 1) : null,
                  icon: Icon(
                    Icons.add_rounded,
                    color: value < 10
                        ? (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  ),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
