// lib/features/profile/screens/chore_preferences_screen.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/models/user_preferences_model.dart';
import 'package:cleanslate/data/repositories/user_preferences_repository.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/services/error_service.dart';

class ChorePreferencesScreen extends StatefulWidget {
  const ChorePreferencesScreen({super.key});

  @override
  State<ChorePreferencesScreen> createState() => _ChorePreferencesScreenState();
}

class _ChorePreferencesScreenState extends State<ChorePreferencesScreen> {
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form state
  late Map<String, bool> _availableDays;
  late Map<String, bool> _timePreferences;
  late Map<String, int> _choreRatings;
  bool _goHomeWeekends = false;
  int _maxChoresPerWeek = 3;
  final bool _hasConnectedCalendar = false;

  // Chore types available
  final List<String> _choreTypes = [
    'Kitchen Cleaning',
    'Bathroom Cleaning',
    'Taking Out Trash',
    'Vacuuming',
    'Mopping',
    'Grocery Shopping',
    'Dishwashing',
    'Restocking Supplies',
  ];

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
    _loadPreferences();
  }

  void _initializeDefaultValues() {
    _availableDays = {
      'monday': false,
      'tuesday': false,
      'wednesday': false,
      'thursday': false,
      'friday': false,
      'saturday': true,
      'sunday': true,
    };

    _timePreferences = {'morning': false, 'afternoon': true, 'evening': true};

    _choreRatings = {};
    for (final chore in _choreTypes) {
      _choreRatings[chore] = 3; // Default neutral rating
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences =
          await _preferencesRepository.getCurrentUserPreferences();

      setState(() {
        // Load available days
        _availableDays = {
          'monday': preferences.availableDays.contains('monday'),
          'tuesday': preferences.availableDays.contains('tuesday'),
          'wednesday': preferences.availableDays.contains('wednesday'),
          'thursday': preferences.availableDays.contains('thursday'),
          'friday': preferences.availableDays.contains('friday'),
          'saturday': preferences.availableDays.contains('saturday'),
          'sunday': preferences.availableDays.contains('sunday'),
        };

        // Load time preferences
        _timePreferences = Map<String, bool>.from(
          preferences.preferredTimeSlots,
        );

        // Load chore ratings based on preferences
        for (final chore in _choreTypes) {
          final choreKey = chore.toLowerCase().replaceAll(' ', '_');
          if (preferences.preferredChoreTypes.contains(choreKey)) {
            _choreRatings[chore] = 5; // Preferred
          } else if (preferences.dislikedChoreTypes.contains(choreKey)) {
            _choreRatings[chore] = 1; // Disliked
          } else {
            _choreRatings[chore] = 3; // Neutral
          }
        }

        _goHomeWeekends = preferences.goHomeWeekends;
        _maxChoresPerWeek = preferences.maxChoresPerWeek;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorService.showError(context, e, operation: 'loadPreferences');
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare preferences data
      final availableDays =
          _availableDays.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();

      final preferredChores =
          _choreRatings.entries
              .where((e) => e.value >= 4)
              .map((e) => e.key.toLowerCase().replaceAll(' ', '_'))
              .toList();

      final dislikedChores =
          _choreRatings.entries
              .where((e) => e.value <= 2)
              .map((e) => e.key.toLowerCase().replaceAll(' ', '_'))
              .toList();

      final preferences = UserPreferences(
        userId: '', // Will be set in repository
        preferredChoreTypes: preferredChores,
        dislikedChoreTypes: dislikedChores,
        availableDays: availableDays,
        preferredTimeSlots: _timePreferences,
        maxChoresPerWeek: _maxChoresPerWeek,
        goHomeWeekends: _goHomeWeekends,
        preferWeekendChores:
            !_goHomeWeekends && _availableDays['saturday']! ||
            _availableDays['sunday']!,
      );

      await _preferencesRepository.saveUserPreferences(preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'savePreferences');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chore Preferences',
          style: TextStyle(fontFamily: 'Switzer'),
        ),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar Connection Card
                    _buildCalendarConnectionCard(isDarkMode),

                    const SizedBox(height: 24),

                    // Available Days Section
                    _buildSectionTitle(
                      'When can you do chores?',
                      Icons.calendar_today,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildDaySelector(isDarkMode),

                    const SizedBox(height: 16),

                    // Weekend availability toggle
                    _buildWeekendToggle(isDarkMode),

                    const SizedBox(height: 24),

                    // Time Preferences
                    _buildSectionTitle(
                      'Preferred times',
                      Icons.access_time,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTimePreferences(isDarkMode),

                    const SizedBox(height: 24),

                    // Chore Preferences
                    _buildSectionTitle(
                      'Rate each chore',
                      Icons.cleaning_services,
                      isDarkMode,
                    ),
                    Text(
                      '1 = Really dislike, 5 = Happy to do',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChoreRatings(isDarkMode),

                    const SizedBox(height: 24),

                    // Workload Settings
                    _buildSectionTitle(
                      'Maximum workload',
                      Icons.fitness_center,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildWorkloadSettings(isDarkMode),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Save Preferences',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Switzer',
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildCalendarConnectionCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _hasConnectedCalendar
                  ? Colors.green
                  : (isDarkMode
                      ? AppColors.borderDark
                      : AppColors.borderPrimary),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _hasConnectedCalendar
                    ? Icons.check_circle
                    : Icons.calendar_month,
                color: _hasConnectedCalendar ? Colors.green : AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasConnectedCalendar
                          ? 'Calendar Connected'
                          : 'Connect Your Calendar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Switzer',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasConnectedCalendar
                          ? 'We\'ll avoid scheduling during your classes'
                          : 'Sync your class schedule for smart chore timing',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_hasConnectedCalendar) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/calendar-connection');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            isDarkMode
                                ? AppColors.borderDark
                                : AppColors.borderPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Connect Calendar',
                      style: TextStyle(fontFamily: 'Switzer'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Switzer',
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _availableDays.entries.map((entry) {
            final day = entry.key;
            final isSelected = entry.value;
            final isWeekend = day == 'saturday' || day == 'sunday';
            final isDisabled = _goHomeWeekends && isWeekend;

            return FilterChip(
              label: Text(
                day.substring(0, 1).toUpperCase() + day.substring(1, 3),
                style: TextStyle(
                  fontFamily: 'VarelaRound',
                  color:
                      isDisabled
                          ? Colors.grey
                          : (isSelected ? Colors.white : AppColors.primary),
                ),
              ),
              selected: isSelected && !isDisabled,
              onSelected:
                  isDisabled
                      ? null
                      : (value) {
                        setState(() {
                          _availableDays[day] = value;
                        });
                      },
              selectedColor: AppColors.primary,
              backgroundColor:
                  isDarkMode ? AppColors.surfaceDark : Colors.grey[200],
              disabledColor:
                  isDarkMode ? AppColors.surfaceDark : Colors.grey[300],
            );
          }).toList(),
    );
  }

  Widget _buildWeekendToggle(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: SwitchListTile(
        title: const Text(
          'I often go home on weekends',
          style: TextStyle(fontFamily: 'Switzer'),
        ),
        subtitle: Text(
          'We\'ll avoid assigning you weekend chores',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontFamily: 'VarelaRound',
          ),
        ),
        value: _goHomeWeekends,
        onChanged: (value) {
          setState(() {
            _goHomeWeekends = value;
            if (value) {
              _availableDays['saturday'] = false;
              _availableDays['sunday'] = false;
            }
          });
        },
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTimePreferences(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: Column(
        children: [
          _buildTimeOption('Morning', '6 AM - 12 PM', 'morning', isDarkMode),
          const Divider(height: 24),
          _buildTimeOption(
            'Afternoon',
            '12 PM - 6 PM',
            'afternoon',
            isDarkMode,
          ),
          const Divider(height: 24),
          _buildTimeOption('Evening', '6 PM - 10 PM', 'evening', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildTimeOption(
    String title,
    String subtitle,
    String key,
    bool isDarkMode,
  ) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontFamily: 'Switzer')),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontFamily: 'VarelaRound',
        ),
      ),
      value: _timePreferences[key] ?? false,
      onChanged: (value) {
        setState(() {
          _timePreferences[key] = value ?? false;
        });
      },
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildChoreRatings(bool isDarkMode) {
    return Column(
      children:
          _choreTypes.map((chore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      chore,
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        final isSelected = _choreRatings[chore] == rating;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _choreRatings[chore] = rating;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : (isDarkMode
                                            ? AppColors.borderDark
                                            : Colors.grey[400]!),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                rating.toString(),
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'VarelaRound',
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildWorkloadSettings(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maximum chores per week',
            style: TextStyle(
              fontFamily: 'Switzer',
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxChoresPerWeek.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _maxChoresPerWeek.toString(),
                  onChanged: (value) {
                    setState(() {
                      _maxChoresPerWeek = value.toInt();
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _maxChoresPerWeek.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
