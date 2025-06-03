// lib/data/repositories/notification_repository.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream to listen for new notifications
  RealtimeChannel? _notificationChannel;

  // Get notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Build the query with dynamic type
      dynamic query = _client
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      query = query.order('created_at', ascending: false);

      if (offset > 0) {
        query = query.range(offset, offset + limit - 1);
      } else {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Subscribe to real-time notifications
  Stream<NotificationModel> subscribeToNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Clean up existing subscription
    _notificationChannel?.unsubscribe();

    // Create a stream controller to manage the notification stream
    final streamController = StreamController<NotificationModel>();

    _notificationChannel =
        _client
            .channel('notifications:$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                if (payload.newRecord != null) {
                  try {
                    final notification = NotificationModel.fromJson(
                      payload.newRecord!,
                    );
                    streamController.add(notification);
                  } catch (e) {
                    print('Error parsing notification: $e');
                  }
                }
              },
            )
            .subscribe();

    return streamController.stream;
  }

  // Unsubscribe from notifications
  void unsubscribeFromNotifications() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  // Create a notification (mainly for testing or manual notifications)
  Future<void> createNotification({
    required String userId,
    String? householdId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'household_id': householdId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Create notification when chore is assigned
  Future<void> notifyChoreAssignment({
    required String assignedToUserId,
    required String assignedByUserId,
    required String choreId,
    required String choreName,
    required String householdId,
  }) async {
    try {
      // Get assigner name
      final assignerProfile =
          await _client
              .from('profiles')
              .select('full_name, email')
              .eq('id', assignedByUserId)
              .single();

      final assignerName =
          assignerProfile['full_name'] ?? assignerProfile['email'];

      await createNotification(
        userId: assignedToUserId,
        householdId: householdId,
        type: 'chore_assigned',
        title: 'Chore Assigned',
        message: '$assignerName assigned you: $choreName',
        metadata: {
          'chore_id': choreId,
          'chore_name': choreName,
          'assigned_by': assignedByUserId,
          'assigner_name': assignerName,
        },
      );
    } catch (e) {
      // Log error but don't throw to avoid disrupting chore assignment
      print('Failed to create assignment notification: $e');
    }
  }

  // Check and create deadline notifications
  Future<void> checkDeadlineNotifications() async {
    try {
      await _client.rpc('check_deadline_notifications');
    } catch (e) {
      print('Failed to check deadline notifications: $e');
    }
  }
}
