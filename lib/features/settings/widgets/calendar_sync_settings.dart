// lib/features/settings/widgets/calendar_sync_settings.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarSyncSettings extends StatefulWidget {
  const CalendarSyncSettings({super.key});

  @override
  State<CalendarSyncSettings> createState() => _CalendarSyncSettingsState();
}

class _CalendarSyncSettingsState extends State<CalendarSyncSettings> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _autoAddChores = true;
  bool _isLoading = true;
  bool _hasCalendarConnected = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Check if user has any calendar connected
      final integrations = await _client
          .from('calendar_integrations')
          .select()
          .eq('user_id', userId)
          .limit(1);

      if ((integrations as List).isNotEmpty) {
        setState(() {
          _hasCalendarConnected = true;
          _autoAddChores = integrations.first['auto_add_chores'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasCalendarConnected = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAutoAddChores(bool value) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('calendar_integrations')
          .update({'auto_add_chores': value})
          .eq('user_id', userId);

      setState(() {
        _autoAddChores = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Chores will be automatically added to your calendar'
                  : 'Automatic calendar sync disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasCalendarConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Calendar Connected',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connect a calendar to sync your chores automatically',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/calendar-connection',
                      ).then((_) => _loadSettings());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Connect Calendar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'CALENDAR SYNC',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
            ),
          ),
          child: SwitchListTile(
            title: const Text(
              'Auto-add chores to calendar',
              style: TextStyle(fontFamily: 'Switzer'),
            ),
            subtitle: const Text(
              'Automatically create calendar events when chores are assigned',
              style: TextStyle(fontSize: 12, fontFamily: 'VarelaRound'),
            ),
            value: _autoAddChores,
            onChanged: _updateAutoAddChores,
            activeThumbColor: AppColors.primary,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.sync, color: AppColors.primary, size: 24),
            ),
          ),
        ),
        if (_autoAddChores)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'New chores will appear in your Google Calendar',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
