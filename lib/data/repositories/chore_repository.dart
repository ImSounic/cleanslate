// lib/data/repositories/chore_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChoreRepository {
  final SupabaseClient _client = Supabase.instance.client;

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
    await _client.from('chore_assignments').insert({
      'chore_id': choreId,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'status': 'pending',
      'priority': priority ?? 'medium',
      'assigned_by': _client.auth.currentUser!.id,
    });
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
      // Start a transaction to ensure both operations complete
      await _client.rpc(
        'delete_chore_and_assignments',
        params: {'chore_id': choreId},
      );
    } catch (e) {
      // If RPC fails or isn't available, fallback to sequential operations
      // 1. Delete all assignments for this chore
      await _client.from('chore_assignments').delete().eq('chore_id', choreId);
      // 2. Delete the chore itself
      await _client.from('chores').delete().eq('id', choreId);
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

    if (updates.isEmpty) return; // No updates to make

    await _client
        .from('chore_assignments')
        .update(updates)
        .eq('id', assignmentId);
  }
}
