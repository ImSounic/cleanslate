// lib/features/calendar/screens/calendar_connection_screen.dart
// Fixed version with proper connection status and hiding other providers when connected

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/services/calendar_service.dart';
import 'package:cleanslate/data/models/calendar_integration_model.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';

class CalendarConnectionScreen extends StatefulWidget {
  const CalendarConnectionScreen({super.key});

  @override
  State<CalendarConnectionScreen> createState() =>
      _CalendarConnectionScreenState();
}

class _CalendarConnectionScreenState extends State<CalendarConnectionScreen> {
  final CalendarService _calendarService = CalendarService();
  List<CalendarIntegration> _connectedCalendars = [];
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _connectingProvider;

  @override
  void initState() {
    super.initState();
    _loadConnectedCalendars();
  }

  Future<void> _loadConnectedCalendars() async {
    try {
      final calendars = await _calendarService.getConnectedCalendars();
      setState(() {
        _connectedCalendars = calendars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectGoogleCalendar() async {
    setState(() {
      _isConnecting = true;
      _connectingProvider = 'google';
    });

    try {
      await _calendarService.connectGoogleCalendar();
      await _loadConnectedCalendars();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect Google Calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
        _connectingProvider = null;
      });
    }
  }

  Future<void> _connectOutlookCalendar() async {
    setState(() {
      _isConnecting = true;
      _connectingProvider = 'outlook';
    });

    try {
      await _calendarService.connectOutlookCalendar();
      await _loadConnectedCalendars();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outlook Calendar connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect Outlook Calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
        _connectingProvider = null;
      });
    }
  }

  Future<void> _connectICalUrl() async {
    final TextEditingController urlController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Calendar URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your university\'s iCal URL:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://calendar.university.edu/...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can usually find this in your university portal',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, urlController.text),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isConnecting = true;
        _connectingProvider = 'ical';
      });

      try {
        await _calendarService.connectICalUrl(result);
        await _loadConnectedCalendars();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calendar URL added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add calendar URL: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isConnecting = false;
          _connectingProvider = null;
        });
      }
    }
  }

  Future<void> _disconnectCalendar(CalendarIntegration calendar) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disconnect Calendar'),
            content: Text(
              'Are you sure you want to disconnect ${calendar.provider.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Disconnect'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _calendarService.disconnectCalendar(calendar.id);
        await _loadConnectedCalendars();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar disconnected')),
          );

          // Notify parent that connection status changed
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect calendar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Check if any calendar is connected
    final hasConnectedCalendar = _connectedCalendars.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Connect Calendar',
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
                    // Info Card
                    _buildInfoCard(isDarkMode),

                    const SizedBox(height: 24),

                    // Connected Calendars
                    if (_connectedCalendars.isNotEmpty) ...[
                      Text(
                        'Connected Calendar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Switzer',
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._connectedCalendars.map(
                        (calendar) =>
                            _buildConnectedCalendarCard(calendar, isDarkMode),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Show available providers only if no calendar is connected
                    if (!hasConnectedCalendar) ...[
                      Text(
                        'Choose a Calendar Provider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Switzer',
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google Calendar
                      _buildProviderCard(
                        provider: 'Google Calendar',
                        description: 'Sync with your Google account',
                        icon: Icons.calendar_today,
                        iconColor: const Color(0xFF4285F4),
                        onTap: _isConnecting ? null : _connectGoogleCalendar,
                        isConnecting: _connectingProvider == 'google',
                        isDarkMode: isDarkMode,
                      ),

                      const SizedBox(height: 12),

                      // Outlook Calendar
                      _buildProviderCard(
                        provider: 'Outlook Calendar',
                        description: 'Sync with your Microsoft account',
                        icon: Icons.mail_outline,
                        iconColor: const Color(0xFF0078D4),
                        onTap: _isConnecting ? null : _connectOutlookCalendar,
                        isConnecting: _connectingProvider == 'outlook',
                        isDarkMode: isDarkMode,
                      ),

                      const SizedBox(height: 12),

                      // iCal URL
                      _buildProviderCard(
                        provider: 'University Calendar URL',
                        description: 'Add your university\'s iCal feed',
                        icon: Icons.link,
                        iconColor: AppColors.primary,
                        onTap: _isConnecting ? null : _connectICalUrl,
                        isConnecting: _connectingProvider == 'ical',
                        isDarkMode: isDarkMode,
                      ),
                    ] else ...[
                      // Show message that only one calendar can be connected
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'To connect a different calendar, please disconnect the current one first.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Privacy Note
                    _buildPrivacyNote(isDarkMode),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why connect your calendar?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Switzer',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll schedule chores around your lectures and study time for maximum convenience',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCalendarCard(
    CalendarIntegration calendar,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calendar.provider.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Switzer',
                  ),
                ),
                if (calendar.calendarEmail != null)
                  Text(
                    calendar.calendarEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                if (calendar.lastSyncAt != null)
                  Text(
                    'Last synced: ${_formatLastSync(calendar.lastSyncAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'VarelaRound',
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (calendar.autoAddChores)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Auto-sync',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _disconnectCalendar(calendar),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String provider,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    required bool isConnecting,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Switzer',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNote(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : Colors.grey[300]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your calendar data is encrypted and only used to schedule chores at convenient times. We never share your data.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'VarelaRound',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final difference = DateTime.now().difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
