import 'package:supabase_flutter/supabase_flutter.dart';

class ChoreRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Create a new chore
  Future<Map<String, dynamic>> createChore({
    required String householdId,
    required String name,
    String? description,
    int? estimatedDuration,
    String frequency = 'weekly',
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
        .eq('status', 'pending')
        .order('due_date', ascending: true);

    return response;
  }

  // Assign a chore to a user
  Future<void> assignChore({
    required String choreId,
    required String assignedTo,
    required DateTime dueDate,
  }) async {
    await _client.from('chore_assignments').insert({
      'chore_id': choreId,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'status': 'pending',
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
}
