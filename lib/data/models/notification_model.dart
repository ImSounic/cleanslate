// lib/data/models/notification_model.dart
import 'package:flutter/material.dart';

enum NotificationType {
  taskAssigned,
  deadlineApproaching,
  deadlineMissed,
  taskCompleted,
  householdJoined,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? relatedItemId; // Could be a chore ID, member ID, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedItemId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: _typeFromString(json['type'] as String),
      isRead: json['is_read'] as bool,
      relatedItemId: json['related_item_id'] as String?,
    );
  }

  // Helper method to convert string to NotificationType
  static NotificationType _typeFromString(String typeStr) {
    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => NotificationType.taskAssigned,
      );
    } catch (e) {
      return NotificationType.taskAssigned;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'is_read': isRead,
      'related_item_id': relatedItemId,
    };
  }

  // Helper method to get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.taskAssigned:
        return Icons.assignment;
      case NotificationType.deadlineApproaching:
        return Icons.timer;
      case NotificationType.deadlineMissed:
        return Icons.warning;
      case NotificationType.taskCompleted:
        return Icons.task_alt;
      case NotificationType.householdJoined:
        return Icons.people;
    }
  }

  // Helper method to get color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.taskAssigned:
        return Colors.blue;
      case NotificationType.deadlineApproaching:
        return Colors.orange;
      case NotificationType.deadlineMissed:
        return Colors.red;
      case NotificationType.taskCompleted:
        return Colors.green;
      case NotificationType.householdJoined:
        return Colors.purple;
    }
  }

  // Create a copy of this notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? relatedItemId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedItemId: relatedItemId ?? this.relatedItemId,
    );
  }
}
