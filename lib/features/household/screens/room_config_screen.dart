// lib/features/household/screens/room_config_screen.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/core/services/error_service.dart';

/// Screen for configuring the number of rooms in a household.
/// Used by the auto-assignment algorithm and chore generation.
class RoomConfigScreen extends StatefulWidget {
  final HouseholdModel household;

  const RoomConfigScreen({super.key, required this.household});

  @override
  State<RoomConfigScreen> createState() => _RoomConfigScreenState();
}

class _RoomConfigScreenState extends State<RoomConfigScreen> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  bool _isSaving = false;

  late int _numKitchens;
  late int _numBathrooms;
  late int _numBedrooms;
  late int _numLivingRooms;

  @override
  void initState() {
    super.initState();
    _numKitchens = widget.household.numKitchens;
    _numBathrooms = widget.household.numBathrooms;
    _numBedrooms = widget.household.numBedrooms;
    _numLivingRooms = widget.household.numLivingRooms;
  }

  bool get _hasChanges =>
      _numKitchens != widget.household.numKitchens ||
      _numBathrooms != widget.household.numBathrooms ||
      _numBedrooms != widget.household.numBedrooms ||
      _numLivingRooms != widget.household.numLivingRooms;

  Future<void> _save() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _householdRepository.updateRoomConfig(
        widget.household.id,
        numKitchens: _numKitchens,
        numBathrooms: _numBathrooms,
        numBedrooms: _numBedrooms,
        numLivingRooms: _numLivingRooms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room configuration saved')),
        );
        Navigator.pop(context, true); // true = changed
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
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Room Configuration',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Room counts help the auto-assignment algorithm distribute cleaning chores fairly across all spaces.',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'VarelaRound',
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Room pickers
            _buildRoomPicker(
              isDarkMode: isDarkMode,
              icon: Icons.countertops_outlined,
              label: 'Kitchens',
              value: _numKitchens,
              min: 0,
              max: 5,
              onChanged: (v) => setState(() => _numKitchens = v),
            ),
            const SizedBox(height: 16),

            _buildRoomPicker(
              isDarkMode: isDarkMode,
              icon: Icons.bathtub_outlined,
              label: 'Bathrooms',
              value: _numBathrooms,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => _numBathrooms = v),
            ),
            const SizedBox(height: 16),

            _buildRoomPicker(
              isDarkMode: isDarkMode,
              icon: Icons.bed_outlined,
              label: 'Bedrooms',
              value: _numBedrooms,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => _numBedrooms = v),
            ),
            const SizedBox(height: 16),

            _buildRoomPicker(
              isDarkMode: isDarkMode,
              icon: Icons.weekend_outlined,
              label: 'Living / Common Areas',
              value: _numLivingRooms,
              min: 0,
              max: 5,
              onChanged: (v) => setState(() => _numLivingRooms = v),
            ),

            const SizedBox(height: 32),

            // Total summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? AppColors.borderDark
                      : AppColors.borderPrimary,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total rooms',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Switzer',
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_numKitchens + _numBathrooms + _numBedrooms + _numLivingRooms}',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Switzer',
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor:
                      (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                          .withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _hasChanges ? 'Save Changes' : 'Done',
                        style: const TextStyle(
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
    );
  }

  Widget _buildRoomPicker({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'VarelaRound',
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          // Stepper controls
          _buildStepperButton(
            isDarkMode: isDarkMode,
            icon: Icons.remove,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Switzer',
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          _buildStepperButton(
            isDarkMode: isDarkMode,
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required bool isDarkMode,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = isDarkMode ? AppColors.primaryDark : AppColors.primary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : (isDarkMode ? AppColors.surfaceDark : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? color
              : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
        ),
      ),
    );
  }
}
