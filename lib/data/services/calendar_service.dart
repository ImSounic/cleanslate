// lib/data/services/calendar_service.dart
// FIXED VERSION - Properly formats Google Calendar API requests

import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/calendar_integration_model.dart';
import 'package:http/http.dart' as http;
import 'package:cleanslate/core/utils/debug_logger.dart';

class CalendarService {
  final SupabaseClient _client = Supabase.instance.client;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  // Get all connected calendars for the current user
  Future<List<CalendarIntegration>> getConnectedCalendars() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('calendar_integrations')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((json) => CalendarIntegration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch connected calendars: $e');
    }
  }

  // Connect Google Calendar
  Future<void> connectGoogleCalendar() async {
    try {
      debugLog('🔄 Starting Google Calendar connection...');

      // Sign in with Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google sign-in cancelled');
      }

      debugLog('✅ Google Calendar sign-in successful');

      // Get authentication tokens
      final auth = await account.authentication;

      // Save to database
      await _client.from('calendar_integrations').upsert({
        'user_id': _client.auth.currentUser!.id,
        'provider': 'google',
        'access_token': auth.accessToken,
        'calendar_id': account.id,
        'calendar_email': account.email,
        'sync_enabled': true,
        'auto_add_chores': true,
        'token_expiry':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      });

      debugLog('✅ Calendar integration saved to database');
    } catch (e) {
      debugLog('❌ Failed to connect Google Calendar: $e');
      throw Exception('Failed to connect Google Calendar: $e');
    }
  }

  // FIXED: Add chore to Google Calendar with proper API formatting
  Future<void> addChoreToGoogleCalendar({
    required String choreName,
    required DateTime scheduledTime,
    required int durationMinutes,
    String? description,
  }) async {
    try {
      debugLog('📅 Starting Google Calendar sync for: $choreName');
      debugLog('📅 Scheduled time: $scheduledTime');

      // Get current user or re-authenticate
      var currentUser = _googleSignIn.currentUser;

      if (currentUser == null) {
        debugLog('🔄 No current user, attempting silent sign-in...');
        currentUser = await _googleSignIn.signInSilently();

        if (currentUser == null) {
          debugLog('🔄 Silent sign-in failed, requesting interactive sign-in...');
          currentUser = await _googleSignIn.signIn();

          if (currentUser == null) {
            throw Exception('User cancelled Google sign-in');
          }
        }
      }

      debugLog('✅ Google Calendar authenticated successfully');

      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugLog('❌ Failed to get authenticated client');
        // Try to re-authenticate
        await _googleSignIn.signOut();
        final account = await _googleSignIn.signIn();
        if (account == null) {
          throw Exception('Failed to re-authenticate with Google');
        }
        final newHttpClient = await _googleSignIn.authenticatedClient();
        if (newHttpClient == null) {
          throw Exception(
            'Failed to get authenticated Google client after re-auth',
          );
        }
        // Use the new client
        final calendarApi = gcal.CalendarApi(newHttpClient);
        await _createCalendarEvent(
          calendarApi,
          choreName,
          scheduledTime,
          durationMinutes,
          description,
        );
      } else {
        // Create Calendar API instance
        final calendarApi = gcal.CalendarApi(httpClient);
        await _createCalendarEvent(
          calendarApi,
          choreName,
          scheduledTime,
          durationMinutes,
          description,
        );
      }
    } catch (e, stackTrace) {
      debugLog('❌ Failed to add chore to Google Calendar: $e');
      debugLog('Stack trace: $stackTrace');

      // Try to provide more specific error messages
      if (e.toString().contains('403')) {
        throw Exception(
          'Calendar permission denied. Please reconnect your calendar.',
        );
      } else if (e.toString().contains('401')) {
        throw Exception(
          'Authentication expired. Please reconnect your calendar.',
        );
      } else if (e.toString().contains('400')) {
        // For 400 errors, try to get more details
        debugLog('400 Error details: $e');
        throw Exception(
          'Calendar sync failed. Please try reconnecting your calendar.',
        );
      } else {
        throw Exception(
          'Failed to add to calendar: ${e.toString().split('.').first}',
        );
      }
    }
  }

  // Helper method to create the calendar event
  Future<void> _createCalendarEvent(
    gcal.CalendarApi calendarApi,
    String choreName,
    DateTime scheduledTime,
    int durationMinutes,
    String? description,
  ) async {
    try {
      // Create the event with minimal required fields first
      final event = gcal.Event();

      // Set summary (title)
      event.summary = '🧹 $choreName';

      // Set description if provided
      if (description != null && description.isNotEmpty) {
        event.description = description;
      }

      // Set start time - FIXED: Ensure proper DateTime format
      final startTime = gcal.EventDateTime();
      startTime.dateTime = scheduledTime.toUtc(); // Convert to UTC
      startTime.timeZone = 'UTC'; // Use UTC to avoid timezone issues
      event.start = startTime;

      // Set end time - FIXED: Ensure proper DateTime format
      final endTime = gcal.EventDateTime();
      endTime.dateTime =
          scheduledTime
              .add(Duration(minutes: durationMinutes))
              .toUtc(); // Convert to UTC
      endTime.timeZone = 'UTC'; // Use UTC to avoid timezone issues
      event.end = endTime;

      // Optional: Set reminders (might cause issues, so making it simpler)
      event.reminders =
          gcal.EventReminders()
            ..useDefault = true; // Just use default reminders

      debugLog('📅 Creating calendar event...');
      debugLog('Event summary: ${event.summary}');
      debugLog('Start time (UTC): ${event.start?.dateTime}');
      debugLog('End time (UTC): ${event.end?.dateTime}');

      // Insert the event - use await and handle the response
      final createdEvent = await calendarApi.events.insert(event, 'primary');

      debugLog('✅ Event created successfully!');
      debugLog('📅 Calendar event created successfully');
      if (createdEvent.htmlLink != null) {
        debugLog('📅 Event has HTML link');
      }

      // Store the event ID if needed
      if (createdEvent.id != null) {
        try {
          await _client.from('scheduled_assignments').insert({
            'user_id': _client.auth.currentUser!.id,
            'calendar_event_id': createdEvent.id,
            'calendar_provider': 'google',
            'synced_to_calendar': true,
            'scheduled_date': scheduledTime.toIso8601String().split('T')[0],
            'scheduled_time':
                '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
            'duration_minutes': durationMinutes,
          });
          debugLog('✅ Event ID stored in database');
        } catch (dbError) {
          debugLog(
            '⚠️ Failed to store event ID in database (non-critical): $dbError',
          );
        }
      }
    } catch (e) {
      debugLog('❌ Error in _createCalendarEvent: $e');
      throw e;
    }
  }

  // Disconnect calendar
  Future<void> disconnectCalendar(String integrationId) async {
    try {
      // Get the integration details first
      final integration =
          await _client
              .from('calendar_integrations')
              .select()
              .eq('id', integrationId)
              .single();

      // If it's Google, sign out
      if (integration['provider'] == 'google') {
        await _googleSignIn.signOut();
      }

      // Delete from database
      await _client
          .from('calendar_integrations')
          .delete()
          .eq('id', integrationId);
    } catch (e) {
      throw Exception('Failed to disconnect calendar: $e');
    }
  }

  // Connect Outlook Calendar (placeholder)
  Future<void> connectOutlookCalendar() async {
    throw Exception('Outlook integration coming soon');
  }

  // Connect iCal URL
  Future<void> connectICalUrl(String calendarUrl) async {
    try {
      // Validate URL
      if (!Uri.tryParse(calendarUrl)!.hasScheme) {
        throw Exception('Invalid calendar URL');
      }

      // Save to database
      await _client.from('calendar_integrations').insert({
        'user_id': _client.auth.currentUser!.id,
        'provider': 'ical_url',
        'calendar_url': calendarUrl,
        'sync_enabled': true,
        'auto_add_chores': false, // Can't add events to iCal URLs
        'is_academic_calendar': true,
      });
    } catch (e) {
      throw Exception('Failed to add calendar URL: $e');
    }
  }

  // Test calendar sync with a simple event
  Future<void> testCalendarSync() async {
    try {
      debugLog('🧪 Running calendar sync test...');

      // Create a test event 1 hour from now
      final testTime = DateTime.now().add(Duration(hours: 1));

      await addChoreToGoogleCalendar(
        choreName: 'Test Chore - CleanSlate',
        scheduledTime: testTime,
        durationMinutes: 30,
        description:
            'This is a test event from CleanSlate to verify calendar sync is working.',
      );

      debugLog('✅ Test completed successfully! Check your Google Calendar.');
    } catch (e) {
      debugLog('❌ Test failed: $e');
      throw e;
    }
  }
}
