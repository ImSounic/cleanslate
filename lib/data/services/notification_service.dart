// lib/data/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/notification_repository.dart';
import 'package:cleanslate/data/models/notification_model.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:cleanslate/data/services/push_notification_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();
  final PushNotificationService _pushService = PushNotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<NotificationModel>? _realtimeSubscription;
  Timer? _deadlineCheckTimer;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasNotifications => _unreadCount > 0;

  // Initialize service
  Future<void> initialize() async {
    debugLog('🔔 NotificationService: Initializing...');
    await _pushService.initialize();
    await loadNotifications();
    _subscribeToRealtimeNotifications();
    _startDeadlineChecker();
  }

  // Clean up
  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _deadlineCheckTimer?.cancel();
    _repository.unsubscribeFromNotifications();
    super.dispose();
  }

  // Load notifications
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    debugLog('🔔 NotificationService: Loading notifications...');
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(
        unreadOnly: unreadOnly,
      );
      _unreadCount = await _repository.getUnreadCount();
      debugLog(
        '🔔 NotificationService: Loaded ${_notifications.length} notifications, $_unreadCount unread',
      );
    } catch (e) {
      debugLog('❌ NotificationService: Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to real-time notifications
  void _subscribeToRealtimeNotifications() {
    try {
      debugLog(
        '🔔 NotificationService: Subscribing to real-time notifications...',
      );
      _realtimeSubscription = _repository.subscribeToNotifications().listen(
        (notification) {
          debugLog(
            '🔔 NotificationService: New real-time notification received: ${notification.title}',
          );
          _notifications.insert(0, notification);
          if (!notification.isRead) {
            _unreadCount++;
          }

          // Show push notification
          _pushService.showNotification(
            title: notification.title,
            body: notification.message,
            payload: notification.id,
          );

          notifyListeners();
        },
        onError: (error) {
          debugLog(
            '❌ NotificationService: Error in notification subscription: $error',
          );
        },
      );
      debugLog('✅ NotificationService: Real-time subscription active');
    } catch (e) {
      debugLog('❌ NotificationService: Failed to subscribe to notifications: $e');
    }
  }

  // Start deadline checker
  void _startDeadlineChecker() {
    // Check for deadlines every hour
    _deadlineCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _repository.checkDeadlineNotifications(),
    );

    // Also check immediately
    _repository.checkDeadlineNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          householdId: _notifications[index].householdId,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          metadata: _notifications[index].metadata,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          updatedAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      debugLog('❌ NotificationService: Failed to mark notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      _notifications =
          _notifications
              .map(
                (n) => NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  householdId: n.householdId,
                  type: n.type,
                  title: n.title,
                  message: n.message,
                  metadata: n.metadata,
                  isRead: true,
                  createdAt: n.createdAt,
                  updatedAt: DateTime.now(),
                ),
              )
              .toList();

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugLog('❌ NotificationService: Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
      );
      if (!notification.isRead && _unreadCount > 0) {
        _unreadCount--;
      }

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugLog('❌ NotificationService: Failed to delete notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _repository.deleteAllNotifications();
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugLog('❌ NotificationService: Failed to clear notifications: $e');
    }
  }

  // Create chore assignment notification
  Future<void> notifyChoreAssignment({
    required String assignedToUserId,
    required String assignedByUserId,
    required String choreId,
    required String choreName,
    required String householdId,
  }) async {
    await _repository.notifyChoreAssignment(
      assignedToUserId: assignedToUserId,
      assignedByUserId: assignedByUserId,
      choreId: choreId,
      choreName: choreName,
      householdId: householdId,
    );
  }

  // Notify all household members when a chore is completed
  Future<void> notifyChoreCompleted({
    required String completedByUserId,
    required String choreId,
    required String choreName,
    required String householdId,
  }) async {
    await _repository.notifyChoreCompleted(
      completedByUserId: completedByUserId,
      choreId: choreId,
      choreName: choreName,
      householdId: householdId,
    );
  }

  // Notify all existing members when a new member joins
  Future<void> notifyMemberJoined({
    required String newMemberUserId,
    required String householdId,
    required String householdName,
  }) async {
    await _repository.notifyMemberJoined(
      newMemberUserId: newMemberUserId,
      householdId: householdId,
      householdName: householdName,
    );
  }

  // Add manual notification to list (for testing)
  void addNotificationManually(NotificationModel notification) {
    debugLog(
      '🔔 NotificationService: Manually adding notification: ${notification.title}',
    );
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }

    // Show push notification
    _pushService.showNotification(
      title: notification.title,
      body: notification.message,
      payload: notification.id,
    );

    notifyListeners();
  }
}
