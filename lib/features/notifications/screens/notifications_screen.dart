// lib/features/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/core/providers/theme_provider.dart'; // Add this import
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/data/models/notification_model.dart';
import 'package:cleanslate/data/repositories/notification_repository.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Add these for testing
  final _supabaseService = SupabaseService();
  final _householdService = HouseholdService();
  final _pushService = PushNotificationService();
  bool _isTestingNotifications = false;

  // Notification preferences
  bool _pushNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🔔 NotificationsScreen: initState called');
    _loadNotificationPreferences();

    // Reload notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔔 NotificationsScreen: Loading notifications after frame');
      context.read<NotificationService>().loadNotifications();
    });
  }

  @override
  void dispose() {
    debugPrint('🔔 NotificationsScreen: dispose called');
    super.dispose();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled =
          prefs.getBool('push_notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      _vibrationEnabled =
          prefs.getBool('notification_vibration_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Test notification creation with phone preview
  Future<void> _createTestNotification(String type) async {
    debugPrint('🧪 TEST: Creating test notification of type: $type');

    setState(() {
      _isTestingNotifications = true;
    });

    try {
      final notificationRepo = NotificationRepository();
      final notificationService = context.read<NotificationService>();
      final currentUser = _supabaseService.currentUser;
      final currentHousehold = _householdService.currentHousehold;

      if (currentUser == null) {
        debugPrint('❌ TEST: No current user found');
        throw Exception('No user logged in');
      }

      debugPrint('🧪 TEST: Current user ID: ${currentUser.id}');
      debugPrint(
        '🧪 TEST: Current household ID: ${currentHousehold?.id ?? "No household"}',
      );

      final testData = _getTestNotificationData(type);

      debugPrint('🧪 TEST: Creating notification with data:');
      debugPrint('  - Type: ${testData['type']}');
      debugPrint('  - Title: ${testData['title']}');
      debugPrint('  - Message: ${testData['message']}');

      // Create the notification in the database
      await notificationRepo.createNotification(
        userId: currentUser.id,
        householdId: currentHousehold?.id,
        type: testData['type']!,
        title: testData['title']!,
        message: testData['message']!,
        metadata: testData['metadata'] as Map<String, dynamic>? ?? {},
      );

      debugPrint('✅ TEST: Notification created successfully');

      // Show phone notification preview immediately
      debugPrint('📱 Showing phone notification preview');
      await _pushService.showNotification(
        title: testData['title']!,
        body: testData['message']!,
        payload:
            'test_${testData['type']}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Force reload notifications to show the new one immediately
      await notificationService.loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test notification created! Check your notification panel 👆',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ TEST: Error creating notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isTestingNotifications = false;
      });
    }
  }

  Map<String, dynamic> _getTestNotificationData(String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    switch (type) {
      case 'chore_assigned':
        return {
          'type': 'chore_assigned',
          'title': 'Chore Assigned',
          'message':
              'Test User assigned you: Clean the kitchen (Test #$timestamp)',
          'metadata': {
            'chore_id': 'test_$timestamp',
            'chore_name': 'Clean Kitchen',
            'assigned_by': 'test_user_123',
            'assigner_name': 'Test User',
          },
        };
      case 'member_joined':
        return {
          'type': 'member_joined',
          'title': 'New Member Joined',
          'message': 'Test User #$timestamp joined your household',
          'metadata': {
            'member_id': 'test_member_$timestamp',
            'member_name': 'Test User',
          },
        };
      case 'deadline_approaching':
        return {
          'type': 'deadline_approaching',
          'title': 'Deadline Approaching',
          'message':
              'Chore "Take out trash" is due in 2 hours (Test #$timestamp)',
          'metadata': {
            'chore_id': 'test_deadline_$timestamp',
            'chore_name': 'Take out trash',
            'hours_remaining': 2,
          },
        };
      case 'chore_completed':
        return {
          'type': 'chore_completed',
          'title': 'Chore Completed',
          'message':
              'Test User completed: Vacuum living room (Test #$timestamp)',
          'metadata': {
            'chore_id': 'test_completed_$timestamp',
            'chore_name': 'Vacuum living room',
            'completed_by': 'test_user_123',
          },
        };
      default:
        return {
          'type': 'chore_created', // Changed from 'test' to valid type
          'title': 'Test Notification',
          'message': 'This is a test notification created at ${DateTime.now()}',
          'metadata': {'test': true, 'timestamp': timestamp},
        };
    }
  }

  void _showTestMenu() {
    // Fix: Use listen: false to avoid the provider error
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🧪 Test Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  fontFamily: 'Switzer',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creates a test notification and shows phone preview',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: Icon(Icons.add_task, color: Colors.blue),
                title: Text(
                  'Test Chore Assignment',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createTestNotification('chore_assigned');
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add, color: Colors.green),
                title: Text(
                  'Test Member Joined',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createTestNotification('member_joined');
                },
              ),
              ListTile(
                leading: Icon(Icons.access_alarm, color: Colors.orange),
                title: Text(
                  'Test Deadline Approaching',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createTestNotification('deadline_approaching');
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  'Test Chore Completed',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createTestNotification('chore_completed');
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.grey),
                title: Text(
                  'Test Generic Notification',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _createTestNotification(
                    'chore_created',
                  ); // Changed from 'test'
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚙️ Notification Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontFamily: 'Switzer',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text(
                      'Push Notifications',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Receive notifications on your device',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        _pushNotificationsEnabled = value;
                      });
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                      _saveNotificationPreference(
                        'push_notifications_enabled',
                        value,
                      );
                    },
                    activeColor: AppColors.primary,
                  ),

                  SwitchListTile(
                    title: Text(
                      'Sound',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Play sound for notifications',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    value: _soundEnabled,
                    onChanged:
                        _pushNotificationsEnabled
                            ? (value) {
                              setModalState(() {
                                _soundEnabled = value;
                              });
                              setState(() {
                                _soundEnabled = value;
                              });
                              _saveNotificationPreference(
                                'notification_sound_enabled',
                                value,
                              );
                            }
                            : null,
                    activeColor: AppColors.primary,
                  ),

                  SwitchListTile(
                    title: Text(
                      'Vibration',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Vibrate for notifications',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    value: _vibrationEnabled,
                    onChanged:
                        _pushNotificationsEnabled
                            ? (value) {
                              setModalState(() {
                                _vibrationEnabled = value;
                              });
                              setState(() {
                                _vibrationEnabled = value;
                              });
                              _saveNotificationPreference(
                                'notification_vibration_enabled',
                                value,
                              );
                            }
                            : null,
                    activeColor: AppColors.primary,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);
    debugPrint('🔔 NotificationsScreen: build called, isDarkMode: $isDarkMode');

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
          ),
          onPressed: () {
            debugPrint('🔔 NotificationsScreen: Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Settings button
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            ),
            onPressed: _showNotificationSettings,
            tooltip: 'Notification Settings',
          ),
          // Test button - only show in debug mode
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.science,
                color:
                    isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
              ),
              onPressed: _isTestingNotifications ? null : _showTestMenu,
              tooltip: 'Test Notifications',
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            ),
            onSelected: (value) async {
              debugPrint('🔔 NotificationsScreen: Menu selected: $value');
              final service = context.read<NotificationService>();
              switch (value) {
                case 'mark_all_read':
                  debugPrint('🔔 Marking all notifications as read');
                  await service.markAllAsRead();
                  break;
                case 'clear_all':
                  debugPrint('🔔 Showing clear all confirmation');
                  _showClearAllConfirmation();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mark all as read',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppColors.error,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          debugPrint('🔔 NotificationsScreen: Consumer rebuild');
          debugPrint('  - isLoading: ${service.isLoading}');
          debugPrint(
            '  - notifications count: ${service.notifications.length}',
          );
          debugPrint('  - unread count: ${service.unreadCount}');

          if (service.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              ),
            );
          }

          if (service.notifications.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return RefreshIndicator(
            onRefresh: () {
              debugPrint('🔔 Pull to refresh triggered');
              return service.loadNotifications();
            },
            color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.notifications.length,
              itemBuilder: (context, index) {
                final notification = service.notifications[index];
                debugPrint(
                  '🔔 Building notification tile $index: ${notification.title}',
                );
                return _buildNotificationTile(notification, isDarkMode);
              },
            ),
          );
        },
      ),
      // Floating test button for quick access in debug mode
      floatingActionButton:
          kDebugMode
              ? FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primary,
                onPressed:
                    _isTestingNotifications
                        ? null
                        : () => _createTestNotification('chore_created'),
                child:
                    _isTestingNotifications
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Icon(Icons.add_alert, color: Colors.white),
                tooltip: 'Quick Test Notification (with phone preview)',
              )
              : null,
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    debugPrint('🔔 Building empty state');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 16,
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
              fontFamily: 'VarelaRound',
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  _isTestingNotifications
                      ? null
                      : () => _createTestNotification('chore_created'),
              icon: const Icon(Icons.science),
              label: const Text('Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creates notification & shows phone preview',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: 'VarelaRound',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
    bool isDarkMode,
  ) {
    final service = context.read<NotificationService>();
    debugPrint(
      '🔔 Building tile for: ${notification.title} (read: ${notification.isRead})',
    );

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        debugPrint('🔔 Dismissing notification: ${notification.id}');
        service.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                debugPrint('🔔 Undo delete requested (not implemented)');
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color:
              notification.isRead
                  ? (isDarkMode
                      ? AppColors.surfaceDark.withOpacity(0.5)
                      : AppColors.surface.withOpacity(0.5))
                  : (isDarkMode ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
            width: notification.isRead ? 0.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () async {
            debugPrint('🔔 Notification tapped: ${notification.id}');
            if (!notification.isRead) {
              debugPrint('🔔 Marking as read: ${notification.id}');
              await service.markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notification.getColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.getIcon(),
              color: notification.getColor(),
              size: 24,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.getTimeAgo(),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark.withOpacity(0.7)
                          : AppColors.textSecondary.withOpacity(0.7),
                  fontFamily: 'VarelaRound',
                ),
              ),
            ],
          ),
          trailing:
              !notification.isRead
                  ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    debugPrint('🔔 Handling notification tap for type: ${notification.type}');

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'chore_created':
      case 'chore_assigned':
      case 'deadline_approaching':
        debugPrint('🔔 Navigating to chore details');
        Navigator.pop(context);
        break;
      case 'member_joined':
        debugPrint('🔔 Navigating to members screen');
        Navigator.pop(context);
        break;
      default:
        debugPrint('🔔 Unknown notification type, no navigation');
        break;
    }
  }

  void _showClearAllConfirmation() {
    debugPrint('🔔 Showing clear all confirmation dialog');
    // Fix: Use listen: false to avoid the provider error
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear All Notifications',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          content: Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'VarelaRound',
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('🔔 Clear all cancelled');
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                debugPrint('🔔 Clearing all notifications');
                Navigator.pop(context);
                await context
                    .read<NotificationService>()
                    .clearAllNotifications();
                debugPrint('✅ All notifications cleared');
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
