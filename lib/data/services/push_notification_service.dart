// lib/services/push_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:cleanslate/core/utils/debug_logger.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugLog('📱 PushNotificationService: Initializing...');

    // Request notification permissions
    await _requestPermissions();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugLog('✅ PushNotificationService: Initialized successfully');
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires explicit permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugLog('📱 Notification tapped: ${response.payload}');
    // You can navigate to specific screens based on the payload
    // For now, we'll just log it
  }

  // Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugLog('⚠️ PushNotificationService: Not initialized, initializing now...');
      await initialize();
    }

    debugLog('📱 Showing notification: $title');

    const androidDetails = AndroidNotificationDetails(
      'cleanslate_channel', // Channel ID
      'CleanSlate Notifications', // Channel name
      channelDescription: 'Notifications for CleanSlate app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
