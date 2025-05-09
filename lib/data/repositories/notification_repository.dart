// lib/data/repositories/notification_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:cleanslate/data/models/notification_model.dart';
import 'package:cleanslate/data/services/notification_service.dart';

class NotificationRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  final String _tableName = 'notifications';

  // Get all notifications for the current user
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to fetch unread notifications count: $e');
    }
  }

  // Create a new notification
  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? userId,
    String? relatedItemId,
    bool showPushNotification = true,
  }) async {
    try {
      // If userId is not provided, use the current user
      final targetUserId = userId ?? _client.auth.currentUser!.id;

      final id = const Uuid().v4();
      final timestamp = DateTime.now();

      final data = {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type.toString().split('.').last,
        'is_read': false,
        'user_id': targetUserId,
        'related_item_id': relatedItemId,
      };

      await _client.from(_tableName).insert(data);

      // Show push notification if requested and it's for the current user
      if (showPushNotification &&
          targetUserId == _client.auth.currentUser!.id) {
        await _notificationService.showNotification(
          id: id.hashCode,
          title: title,
          body: message,
          payload: relatedItemId,
        );
      }

      return NotificationModel(
        id: id,
        title: title,
        message: message,
        timestamp: timestamp,
        type: type,
        relatedItemId: relatedItemId,
      );
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client
          .from(_tableName)
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from(_tableName).delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Generate notifications for different events

  // Task assigned notification
  Future<void> createTaskAssignedNotification({
    required String assigneeId,
    required String choreName,
    required String assignerName,
    required String choreId,
  }) async {
    final title = 'New Chore Alert! 🧹';
    final message =
        '$assignerName has entrusted you with "$choreName". The torch has been passed!';

    await createNotification(
      title: title,
      message: message,
      type: NotificationType.taskAssigned,
      userId: assigneeId,
      relatedItemId: choreId,
    );
  }

  // Deadline approaching notification (1 day before)
  Future<void> createDeadlineApproachingNotification({
    required String userId,
    required String choreName,
    required String choreId,
  }) async {
    final title = 'Tick Tock! ⏰';
    final message =
        '"$choreName" is due tomorrow. Time to channel your inner superhero!';

    await createNotification(
      title: title,
      message: message,
      type: NotificationType.deadlineApproaching,
      userId: userId,
      relatedItemId: choreId,
    );
  }

  // Deadline missed notification
  Future<void> createDeadlineMissedNotification({
    required String userId,
    required String choreName,
    required String choreId,
  }) async {
    final title = 'Oops! Time Flew By ⏳';
    final message =
        'The deadline for "$choreName" has passed. No worries, even Batman misses things sometimes!';

    await createNotification(
      title: title,
      message: message,
      type: NotificationType.deadlineMissed,
      userId: userId,
      relatedItemId: choreId,
    );
  }

  // Task completed notification (for household members)
  Future<void> createTaskCompletedNotification({
    required String completedByName,
    required String choreName,
    required String choreId,
    required List<String> householdMemberIds,
  }) async {
    final title = 'Chore Champion! 🏆';
    final message =
        '$completedByName just conquered "$choreName". High fives all around!';

    // Create notification for all household members except the person who completed it
    for (final memberId in householdMemberIds) {
      await createNotification(
        title: title,
        message: message,
        type: NotificationType.taskCompleted,
        userId: memberId,
        relatedItemId: choreId,
        showPushNotification: memberId == _client.auth.currentUser!.id,
      );
    }
  }

  // Household joined notification
  Future<void> createHouseholdJoinedNotification({
    required String newMemberName,
    required String householdName,
    required String householdId,
    required List<String> memberIds,
  }) async {
    final title = 'New Roomie Alert! 🎉';
    final message =
        '$newMemberName has joined "$householdName". Let the fun begin!';

    for (final memberId in memberIds) {
      await createNotification(
        title: title,
        message: message,
        type: NotificationType.householdJoined,
        userId: memberId,
        relatedItemId: householdId,
        showPushNotification: memberId == _client.auth.currentUser!.id,
      );
    }
  }
}
