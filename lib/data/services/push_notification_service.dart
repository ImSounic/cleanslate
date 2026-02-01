// lib/data/services/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:cleanslate/core/utils/debug_logger.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugLog('📱 PushNotificationService: Initializing...');

    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications (for foreground display)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get and save FCM token
    await _setupFCMToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugLog('📱 FCM token refreshed');
      _fcmToken = newToken;
      _saveFCMToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugLog('📱 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
    debugLog('✅ PushNotificationService: Initialized with FCM');
  }

  Future<void> _requestPermissions() async {
    // Firebase messaging permission request
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugLog('📱 FCM permission status: ${settings.authorizationStatus}');

    // Android 13+ explicit permission
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _setupFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugLog('📱 FCM Token: ${_fcmToken?.substring(0, 20)}...');

      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }
    } catch (e) {
      debugLog('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
      debugLog('✅ FCM token saved to Supabase');
    } catch (e) {
      debugLog('❌ Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    try {
      if (_fcmToken == null) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', _fcmToken!);
      debugLog('✅ FCM token removed from Supabase');
    } catch (e) {
      debugLog('❌ Failed to remove FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugLog('📱 Foreground message: ${message.notification?.title}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'CleanSlate',
        body: message.notification!.body ?? '',
        payload: message.data['notification_id'],
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugLog('📱 Notification tapped: ${message.data}');
    // Navigation can be handled here based on message.data
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugLog('📱 Local notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugLog('⚠️ PushNotificationService: Not initialized, initializing now...');
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'cleanslate_channel',
      'CleanSlate Notifications',
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
