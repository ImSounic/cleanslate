// lib/data/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cleanslate/data/repositories/notification_repository.dart';
import 'package:cleanslate/data/models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();

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
    await loadNotifications();
    _subscribeToRealtimeNotifications();
    _startDeadlineChecker();
  }

  // Clean up
  void dispose() {
    _realtimeSubscription?.cancel();
    _deadlineCheckTimer?.cancel();
    _repository.unsubscribeFromNotifications();
    super.dispose();
  }

  // Load notifications
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(
        unreadOnly: unreadOnly,
      );
      _unreadCount = await _repository.getUnreadCount();
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to real-time notifications
  void _subscribeToRealtimeNotifications() {
    try {
      _realtimeSubscription = _repository.subscribeToNotifications().listen(
        (notification) {
          _notifications.insert(0, notification);
          if (!notification.isRead) {
            _unreadCount++;
          }
          notifyListeners();
        },
        onError: (error) {
          print('Error in notification subscription: $error');
        },
      );
    } catch (e) {
      print('Failed to subscribe to notifications: $e');
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
      print('Failed to mark notification as read: $e');
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
      print('Failed to mark all as read: $e');
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
      print('Failed to delete notification: $e');
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
      print('Failed to clear notifications: $e');
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
}
