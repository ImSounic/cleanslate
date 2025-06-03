// lib/data/models/notification_model.dart
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String? householdId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.householdId,
    required this.type,
    required this.title,
    required this.message,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      householdId: json['household_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'household_id': householdId,
      'type': type,
      'title': title,
      'message': message,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get icon based on notification type
  IconData getIcon() {
    switch (type) {
      case 'chore_created':
        return Icons.add_task;
      case 'member_joined':
        return Icons.person_add;
      case 'deadline_approaching':
        return Icons.access_alarm;
      case 'chore_assigned':
        return Icons.assignment_ind;
      case 'chore_completed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  // Helper method to get color based on notification type
  Color getColor() {
    switch (type) {
      case 'chore_created':
        return Colors.blue;
      case 'member_joined':
        return Colors.green;
      case 'deadline_approaching':
        return Colors.orange;
      case 'chore_assigned':
        return Colors.purple;
      case 'chore_completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format time ago
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
