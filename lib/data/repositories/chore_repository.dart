// lib/data/repositories/chore_repository.dart
// COMPLETE REPLACEMENT - Copy this entire file

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/data/services/calendar_service.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

class ChoreRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final NotificationService _notificationService;
  final CalendarService _calendarService;

  ChoreRepository({
    NotificationService? notificationService,
    CalendarService? calendarService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _calendarService = calendarService ?? CalendarService();

  // Create a new chore
  Future<Map<String, dynamic>> createChore({
    required String householdId,
    required String name,
    String? description,
    int? estimatedDuration,
    String? frequency = 'weekly',
    bool isRecurring = false,
  }) async {
    final response =
        await _client
            .from('chores')
            .insert({
              'household_id': householdId,
              'name': name,
              'description': description,
              'estimated_duration': estimatedDuration,
              'frequency': frequency,
              'is_recurring': isRecurring,
              'created_by': _client.auth.currentUser!.id,
            })
            .select()
            .single();

    return response;
  }

  // Get chores for a household
  Future<List<Map<String, dynamic>>> getChoresForHousehold(
    String householdId,
  ) async {
    final response = await _client
        .from('chores')
        .select('*, chore_assignments(*)')
        .eq('household_id', householdId)
        .order('created_at', ascending: false);

    return response;
  }

  // Get chores assigned to the current user
  Future<List<Map<String, dynamic>>> getMyChores() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('chore_assignments')
        .select('*, chores(*)')
        .eq('assigned_to', userId)
        .order('due_date', ascending: true);

    return response;
  }

  // UPDATED: Assign a chore to a user WITH calendar sync
  Future<void> assignChore({
    required String choreId,
    required String assignedTo,
    required DateTime dueDate,
    String? priority,
  }) async {
    try {
      debugLog('📝 Starting chore assignment...');

      // Create the assignment in database
      final assignmentResponse =
          await _client
              .from('chore_assignments')
              .insert({
                'chore_id': choreId,
                'assigned_to': assignedTo,
                'due_date': dueDate.toIso8601String(),
                'status': 'pending',
                'priority': priority ?? 'medium',
                'assigned_by': _client.auth.currentUser!.id,
              })
              .select()
              .single();

      debugLog('✅ Chore assignment created successfully');

      // Get chore details for notification and calendar
      final chore =
          await _client
              .from('chores')
              .select('name, household_id, description, estimated_duration')
              .eq('id', choreId)
              .single();

      // Create notification for the assigned user
      if (_client.auth.currentUser!.id != assignedTo) {
        await _notificationService.notifyChoreAssignment(
          assignedToUserId: assignedTo,
          assignedByUserId: _client.auth.currentUser!.id,
          choreId: choreId,
          choreName: chore['name'],
          householdId: chore['household_id'],
        );
      }

      // Add to calendar if user has calendar connected and auto-sync enabled
      debugLog('🔄 Attempting to sync to calendar...');
      await _syncChoreToCalendar(
        assignmentId: assignmentResponse['id'],
        userId: assignedTo,
        choreName: chore['name'],
        choreDescription: chore['description'],
        dueDate: dueDate,
        estimatedDuration: chore['estimated_duration'] ?? 30,
      );
    } catch (e) {
      debugLog('❌ Error in assignChore: $e');
      // Don't throw - assignment was successful even if calendar sync failed
      if (e.toString().contains('chore_assignments')) {
        rethrow; // Re-throw database errors
      }
    }
  }

  // Private method to sync chore to calendar
  Future<void> _syncChoreToCalendar({
    required String assignmentId,
    required String userId,
    required String choreName,
    String? choreDescription,
    required DateTime dueDate,
    required int estimatedDuration,
  }) async {
    try {
      debugLog('📅 Checking calendar integration for user...');

      // Check if user has calendar integration enabled
      final integrations = await _client
          .from('calendar_integrations')
          .select()
          .eq('user_id', userId)
          .eq('sync_enabled', true)
          .eq('auto_add_chores', true);

      if ((integrations as List).isEmpty) {
        debugLog('⚠️ User has no calendar integration or sync disabled');
        return;
      }

      debugLog('✅ Found ${integrations.length} calendar integration(s)');

      // Get the first active integration (usually Google)
      final integration = integrations.first;

      if (integration['provider'] == 'google') {
        debugLog('🔄 Syncing to Google Calendar...');

        // Add to Google Calendar
        await _calendarService.addChoreToGoogleCalendar(
          choreName: choreName,
          scheduledTime: dueDate,
          durationMinutes: estimatedDuration,
          description:
              choreDescription ?? 'Household chore assigned via CleanSlate',
        );

        // Store the calendar sync info
        await _client.from('scheduled_assignments').insert({
          'assignment_id': assignmentId,
          'user_id': userId,
          'scheduled_date': dueDate.toIso8601String().split('T')[0],
          'scheduled_time':
              "${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}",
          'duration_minutes': estimatedDuration,
          'synced_to_calendar': true,
          'calendar_provider': 'google',
        });

        debugLog('✅ Chore successfully added to Google Calendar!');
      } else {
        debugLog(
          '⚠️ Calendar provider ${integration['provider']} not yet supported',
        );
      }
    } catch (e) {
      debugLog('❌ Failed to sync chore to calendar: $e');
      // Don't throw - this shouldn't break the assignment
    }
  }

  // Mark a chore as complete
  Future<void> completeChore(String assignmentId) async {
    await _client
        .from('chore_assignments')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assignmentId);
  }

  // Unmark a chore as complete (set back to pending)
  Future<void> uncompleteChore(String assignmentId) async {
    await _client
        .from('chore_assignments')
        .update({'status': 'pending', 'completed_at': null})
        .eq('id', assignmentId);
  }

  // Delete a chore assignment
  Future<void> deleteChoreAssignment(String assignmentId) async {
    // First, check if the assignment exists
    final assignment =
        await _client
            .from('chore_assignments')
            .select('id')
            .eq('id', assignmentId)
            .maybeSingle();

    if (assignment == null) {
      throw Exception('Chore assignment not found');
    }

    // Delete the assignment
    await _client.from('chore_assignments').delete().eq('id', assignmentId);
  }

  // Delete a chore and all its assignments
  Future<void> deleteChore(String choreId) async {
    try {
      // First delete all assignments related to this chore
      await _client.from('chore_assignments').delete().eq('chore_id', choreId);

      // Then delete the chore itself
      await _client.from('chores').delete().eq('id', choreId);
    } catch (e) {
      throw Exception('Failed to delete chore: $e');
    }
  }

  // Update a chore's details (name, description, frequency)
  Future<void> updateChore({
    required String choreId,
    String? name,
    String? description,
    String? frequency,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (frequency != null) updates['frequency'] = frequency;

    if (updates.isNotEmpty) {
      await _client.from('chores').update(updates).eq('id', choreId);
    }
  }

  // Update a chore assignment
  Future<void> updateChoreAssignment({
    required String assignmentId,
    String? assignedTo,
    DateTime? dueDate,
    String? priority,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (assignedTo != null) updates['assigned_to'] = assignedTo;
    if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
    if (priority != null) updates['priority'] = priority;
    if (status != null) updates['status'] = status;

    await _client
        .from('chore_assignments')
        .update(updates)
        .eq('id', assignmentId);
  }

  // Test method to directly test calendar sync
  Future<void> testCalendarSync() async {
    try {
      debugLog('🧪 Testing calendar sync...');
      final userId = _client.auth.currentUser!.id;

      // Create a test chore
      await _calendarService.addChoreToGoogleCalendar(
        choreName: 'Test Chore - Delete Me',
        scheduledTime: DateTime.now().add(Duration(hours: 1)),
        durationMinutes: 30,
        description: 'This is a test chore to verify calendar sync is working',
      );

      debugLog('✅ Test chore added to calendar successfully!');
    } catch (e) {
      debugLog('❌ Test failed: $e');
      rethrow;
    }
  }
}
