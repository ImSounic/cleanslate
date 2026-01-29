// lib/data/models/calendar_integration_model.dart

import 'package:flutter/material.dart';

class CalendarIntegration {
  final String id;
  final String userId;
  final CalendarProvider provider;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final String? calendarId;
  final String? calendarEmail;
  final String? calendarUrl;
  final bool syncEnabled;
  final bool autoAddChores;
  final bool isAcademicCalendar;
  final DateTime? lastSyncAt;
  final DateTime createdAt;

  CalendarIntegration({
    required this.id,
    required this.userId,
    required this.provider,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.calendarId,
    this.calendarEmail,
    this.calendarUrl,
    this.syncEnabled = true,
    this.autoAddChores = true,
    this.isAcademicCalendar = false,
    this.lastSyncAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CalendarIntegration.fromJson(Map<String, dynamic> json) {
    return CalendarIntegration(
      id: json['id'],
      userId: json['user_id'],
      provider: CalendarProvider.fromString(json['provider']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenExpiry:
          json['token_expiry'] != null
              ? DateTime.parse(json['token_expiry'])
              : null,
      calendarId: json['calendar_id'],
      calendarEmail: json['calendar_email'],
      calendarUrl: json['calendar_url'],
      syncEnabled: json['sync_enabled'] ?? true,
      autoAddChores: json['auto_add_chores'] ?? true,
      isAcademicCalendar: json['is_academic_calendar'] ?? false,
      lastSyncAt:
          json['last_sync_at'] != null
              ? DateTime.parse(json['last_sync_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.value,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expiry': tokenExpiry?.toIso8601String(),
      'calendar_id': calendarId,
      'calendar_email': calendarEmail,
      'calendar_url': calendarUrl,
      'sync_enabled': syncEnabled,
      'auto_add_chores': autoAddChores,
      'is_academic_calendar': isAcademicCalendar,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (tokenExpiry == null) return false;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  bool get needsRefresh {
    if (tokenExpiry == null) return false;
    // Refresh if token expires in less than 5 minutes
    return DateTime.now().isAfter(
      tokenExpiry!.subtract(const Duration(minutes: 5)),
    );
  }
}

enum CalendarProvider {
  google('google'),
  outlook('outlook'),
  apple('apple'),
  icalUrl('ical_url');

  final String value;
  const CalendarProvider(this.value);

  static CalendarProvider fromString(String value) {
    return CalendarProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarProvider.google,
    );
  }

  String get displayName {
    switch (this) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.outlook:
        return 'Outlook Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
      case CalendarProvider.icalUrl:
        return 'iCal URL';
    }
  }

  /// Returns a Material icon suitable for this calendar provider.
  /// Previously referenced non-existent PNG assets; now uses built-in icons.
  IconData get iconData {
    switch (this) {
      case CalendarProvider.google:
        return Icons.event;
      case CalendarProvider.outlook:
        return Icons.calendar_month;
      case CalendarProvider.apple:
        return Icons.apple;
      case CalendarProvider.icalUrl:
        return Icons.link;
    }
  }
}
