// lib/features/household/screens/household_config_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/services/chore_initialization_service.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'package:cleanslate/core/services/error_service.dart';

class HouseholdConfigScreen extends StatefulWidget {
  final List<HouseholdMemberModel> members;

  const HouseholdConfigScreen({
    super.key,
    required this.members,
  });

  @override
  State<HouseholdConfigScreen> createState() => _HouseholdConfigScreenState();
}

class _HouseholdConfigScreenState extends State<HouseholdConfigScreen> {
  final _householdRepository = HouseholdRepository();
  
  late int _numKitchens;
  late int _numBathrooms;
  late int _numBedrooms;
  late int _numLivingRooms;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final household = HouseholdService().currentHousehold;
    _numKitchens = household?.numKitchens ?? 1;
    _numBathrooms = household?.numBathrooms ?? 1;
    _numBedrooms = household?.numBedrooms ?? 1;
    _numLivingRooms = household?.numLivingRooms ?? 1;
  }

  Future<void> _saveAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      final household = HouseholdService().currentHousehold;
      if (household == null) throw Exception('No household');

      // Save configuration
      await _householdRepository.updateRoomConfig(
        household.id,
        numKitchens: _numKitchens,
        numBathrooms: _numBathrooms,
        numBedrooms: _numBedrooms,
        numLivingRooms: _numLivingRooms,
      );

      // Reload household to get updated config
      final freshHousehold = await _householdRepository.getHouseholdModel(household.id);
      HouseholdService().setCurrentHousehold(freshHousehold);

      // Initialize chores
      final memberIds = widget.members.map((m) => m.userId).toList();
      final initService = ChoreInitializationService();
      final count = await initService.initializeChores(
        household: freshHousehold,
        memberIds: memberIds,
      );

      if (mounted) {
        Navigator.pop(context, count); // Return the count of chores created
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'initializeChores');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? AppColors.iconPrimaryDark : AppColors.iconPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configure Your Home',
          style: TextStyle(
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 60,
                    color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Description
              Text(
                'Tell us about your home',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Switzer',
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll create chores based on your home setup and assign them to household members in rotation.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'VarelaRound',
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

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
                        icon: '🛏️',
                        label: 'Bedrooms',
                        value: _numBedrooms,
                        onChanged: (v) => setState(() => _numBedrooms = v),
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
                      const SizedBox(height: 24),
                      
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
                              Icons.people_rounded,
                              size: 28,
                              color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.members.length} household member${widget.members.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'VarelaRound',
                                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Chores will rotate between everyone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'VarelaRound',
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Assign button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndInitialize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: (isDarkMode ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Assign Chores Automatically',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
