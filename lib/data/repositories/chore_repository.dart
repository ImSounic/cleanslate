// lib/data/repositories/chore_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/repositories/notification_repository.dart';
import 'package:cleanslate/data/models/notification_model.dart';

class ChoreRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  // Create a new chore
  Future<Map<String, dynamic>> createChore({
    required String householdId,
    required String name,
    String? description,
    int? estimatedDuration,
    String? frequency = 'weekly',
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
        // Removed the .eq('status', 'pending') filter to get all chores
        .order('due_date', ascending: true);

    return response;
  }

  // Assign a chore to a user
  Future<void> assignChore({
    required String choreId,
    required String assignedTo,
    required DateTime dueDate,
    String? priority,
  }) async {
    // First, insert the assignment
    await _client.from('chore_assignments').insert({
      'chore_id': choreId,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'status': 'pending',
      'priority': priority ?? 'medium',
      'assigned_by': _client.auth.currentUser!.id,
      'deadline_notified': false,
      'missed_deadline_notified': false,
    });

    // Then fetch the chore and assigner info to create notification
    try {
      final choreResponse =
          await _client
              .from('chores')
              .select('name')
              .eq('id', choreId)
              .single();

      final assignerUserId = _client.auth.currentUser!.id;
      // Get assigner name from user metadata
      final assignerUserData = _client.auth.currentUser!.userMetadata;
      final assignerName =
          assignerUserData?['full_name'] as String? ?? 'Someone';

      final choreName = choreResponse['name'] as String;

      // Create notification
      await _notificationRepository.createTaskAssignedNotification(
        assigneeId: assignedTo,
        choreName: choreName,
        assignerName: assignerName,
        choreId: choreId,
      );
    } catch (e) {
      print('Error creating assignment notification: $e');
      // Continue even if notification creation fails
    }
  }

  // Mark a chore as complete
  Future<void> completeChore(String assignmentId) async {
    // First, update the assignment status
    await _client
        .from('chore_assignments')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assignmentId);

    // Then create notifications
    try {
      // Get assignment details
      final assignmentResponse =
          await _client
              .from('chore_assignments')
              .select('*, chores(*)')
              .eq('id', assignmentId)
              .single();

      final choreId = assignmentResponse['chore_id'] as String;
      final choreName = assignmentResponse['chores']['name'] as String;
      final householdId =
          assignmentResponse['chores']['household_id'] as String;
      final completedByUserId = _client.auth.currentUser!.id;

      // Get completer's name from user metadata
      final userMetadata = _client.auth.currentUser!.userMetadata;
      final completedByName =
          userMetadata?['full_name'] as String? ?? 'Someone';

      // Get all household members
      final membersResponse = await _client
          .from('household_members')
          .select('user_id')
          .eq('household_id', householdId)
          .eq('is_active', true)
          .neq(
            'user_id',
            completedByUserId,
          ); // Exclude the person who completed it

      final memberIds =
          (membersResponse as List)
              .map((member) => member['user_id'] as String)
              .toList();

      // Create notifications for other household members
      if (memberIds.isNotEmpty) {
        await _notificationRepository.createTaskCompletedNotification(
          completedByName: completedByName,
          choreName: choreName,
          choreId: choreId,
          householdMemberIds: memberIds,
        );
      }
    } catch (e) {
      print('Error creating completion notification: $e');
      // Continue even if notification creation fails
    }
  }

  // Unmark a chore as complete (set back to pending)
  Future<void> uncompleteChore(String assignmentId) async {
    await _client
        .from('chore_assignments')
        .update({'status': 'pending', 'completed_at': null})
        .eq('id', assignmentId);
  }

  // Check for approaching deadlines and create notifications
  Future<void> checkDeadlinesAndCreateNotifications() async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final today = DateTime(now.year, now.month, now.day);

      // Get chores due tomorrow that haven't been notified yet
      final response = await _client
          .from('chore_assignments')
          .select('id, chore_id, assigned_to, chores(*)')
          .eq('status', 'pending')
          .gte('due_date', tomorrow.toIso8601String())
          .lt(
            'due_date',
            DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day + 1,
            ).toIso8601String(),
          )
          .eq('deadline_notified', false);

      for (final assignment in response as List) {
        final assignedTo = assignment['assigned_to'] as String;
        final choreId = assignment['chore_id'] as String;
        final choreName = assignment['chores']['name'] as String;

        // Create approaching deadline notification
        await _notificationRepository.createDeadlineApproachingNotification(
          userId: assignedTo,
          choreName: choreName,
          choreId: choreId,
        );

        // Mark as notified
        await _client
            .from('chore_assignments')
            .update({'deadline_notified': true})
            .eq('id', assignment['id']);
      }

      // Check for missed deadlines
      final missedResponse = await _client
          .from('chore_assignments')
          .select('id, chore_id, assigned_to, chores(*)')
          .eq('status', 'pending')
          .lt('due_date', today.toIso8601String())
          .eq('missed_deadline_notified', false);

      for (final assignment in missedResponse as List) {
        final assignedTo = assignment['assigned_to'] as String;
        final choreId = assignment['chore_id'] as String;
        final choreName = assignment['chores']['name'] as String;

        // Create missed deadline notification
        await _notificationRepository.createDeadlineMissedNotification(
          userId: assignedTo,
          choreName: choreName,
          choreId: choreId,
        );

        // Mark as notified
        await _client
            .from('chore_assignments')
            .update({'missed_deadline_notified': true})
            .eq('id', assignment['id']);
      }
    } catch (e) {
      print('Error checking deadlines: $e');
    }
  }
}
