// lib/data/services/recurrence_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/data/services/chore_assignment_service.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

/// Manages recurring chore generation.
///
/// Two entry points:
/// 1. [onChoreCompleted] — called when user completes a recurring chore,
///    immediately generates the next instance.
/// 2. [processAllRecurringChores] — called on app open to catch up on
///    any missed generations.
class RecurrenceService {
  final SupabaseClient _client = Supabase.instance.client;
  final ChoreRepository _choreRepository = ChoreRepository();
  final ChoreAssignmentService _assignmentService = ChoreAssignmentService();

  // ── Frequency helpers ───────────────────────────────────────────────

  /// Calculate the next due date given the current due date and frequency.
  /// Returns `null` for non-recurring (once) chores.
  static DateTime? calculateNextDueDate(
    DateTime currentDueDate,
    String? frequency,
  ) {
    switch (frequency?.toLowerCase()) {
      case 'daily':
        return currentDueDate.add(const Duration(days: 1));
      case 'weekly':
        return currentDueDate.add(const Duration(days: 7));
      case 'biweekly':
        return currentDueDate.add(const Duration(days: 14));
      case 'weekdays':
        // Next weekday
        var next = currentDueDate.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'weekends':
        // Next weekend day
        var next = currentDueDate.add(const Duration(days: 1));
        while (next.weekday != DateTime.saturday &&
            next.weekday != DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'monthly':
        // Same day next month (clamped to valid day)
        final nextMonth = currentDueDate.month == 12
            ? DateTime(currentDueDate.year + 1, 1, 1)
            : DateTime(currentDueDate.year, currentDueDate.month + 1, 1);
        final lastDay =
            DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final day =
            currentDueDate.day > lastDay ? lastDay : currentDueDate.day;
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          day,
          currentDueDate.hour,
          currentDueDate.minute,
        );
      case 'once':
      case null:
        return null; // Not recurring
      default:
        return null;
    }
  }

  /// Whether a frequency string represents a recurring schedule.
  static bool isRecurring(String? frequency) {
    if (frequency == null) return false;
    return frequency.toLowerCase() != 'once' &&
        calculateNextDueDate(DateTime.now(), frequency) != null;
  }

  // ── Core: generate next instance ────────────────────────────────────

  /// Called when a recurring chore assignment is completed.
  ///
  /// Generates the next instance with a new due date and (optionally)
  /// auto-assigns it.
  Future<Map<String, dynamic>?> onChoreCompleted({
    required String choreId,
    required String assignmentId,
    required String householdId,
    bool autoAssign = true,
  }) async {
    try {
      // 1. Fetch the chore details
      final chore =
          await _client.from('chores').select().eq('id', choreId).single();

      final frequency = chore['frequency'] as String?;
      if (!isRecurring(frequency)) return null;

      // 2. Find the assignment to get current due date + assignee
      final assignment = await _client
          .from('chore_assignments')
          .select()
          .eq('id', assignmentId)
          .single();

      final currentDueDate = assignment['due_date'] != null
          ? DateTime.parse(assignment['due_date'] as String)
          : DateTime.now();

      final nextDueDate = calculateNextDueDate(currentDueDate, frequency);
      if (nextDueDate == null) return null;

      debugLog(
        '🔄 Recurring: generating next instance of "${chore['name']}" '
        'due ${nextDueDate.toIso8601String().split('T')[0]}',
      );

      // 3. Determine the parent ID (for tracking lineage)
      //    If this chore already has a parent, use that; otherwise it IS the parent
      final parentId =
          (chore['recurrence_parent_id'] as String?) ?? choreId;

      // 4. Create the new chore instance
      final newChore = await _client
          .from('chores')
          .insert({
            'household_id': householdId,
            'name': chore['name'],
            'description': chore['description'],
            'estimated_duration': chore['estimated_duration'],
            'frequency': frequency,
            'is_recurring': true,
            'recurrence_parent_id': parentId,
            'created_by': chore['created_by'],
          })
          .select()
          .single();

      // 5. Assign the new instance
      String? assigneeId;
      if (autoAssign) {
        assigneeId = await _assignmentService.findBestAssignee(
          householdId: householdId,
          choreName: chore['name'] as String,
          dueDate: nextDueDate,
        );
      }
      // Fall back to same person if algorithm returns null
      assigneeId ??= assignment['assigned_to'] as String?;

      if (assigneeId != null) {
        await _choreRepository.assignChore(
          choreId: newChore['id'],
          assignedTo: assigneeId,
          dueDate: nextDueDate,
          priority: assignment['priority'] as String? ?? 'medium',
        );
      }

      // 6. Update last_generated_date on the parent template
      await _client
          .from('chores')
          .update({
            'last_generated_date': DateTime.now().toIso8601String().split('T')[0],
          })
          .eq('id', parentId);

      debugLog('✅ Next instance created: ${newChore['id']}');
      return newChore;
    } catch (e) {
      debugLog('❌ Failed to generate recurring instance: $e');
      return null;
    }
  }

  // ── Catch-up: process all recurring chores ──────────────────────────

  /// Called on app open. Checks all recurring chores in the household
  /// and generates any missing instances.
  ///
  /// Logic: if the latest assignment for a recurring chore is completed
  /// and no pending/in_progress assignment exists, generate the next one.
  Future<int> processAllRecurringChores(String householdId) async {
    try {
      debugLog('🔄 Processing recurring chores for household $householdId');

      // Get all recurring chores (templates) for this household
      final recurringChores = await _client
          .from('chores')
          .select('id, name, frequency, recurrence_parent_id')
          .eq('household_id', householdId)
          .eq('is_recurring', true);

      // Also get all "original" chores with a recurring frequency that
      // aren't marked is_recurring yet (legacy data)
      final legacyRecurring = await _client
          .from('chores')
          .select('id, name, frequency')
          .eq('household_id', householdId)
          .eq('is_recurring', false)
          .neq('frequency', 'once');

      // Combine both sets, using a Set to avoid duplicates
      final choreIds = <String>{};
      final choresToCheck = <Map<String, dynamic>>[];

      for (final c in [...recurringChores as List, ...legacyRecurring as List]) {
        final id = c['id'] as String;
        if (choreIds.add(id)) {
          choresToCheck.add(c);
        }
      }

      int generated = 0;

      for (final chore in choresToCheck) {
        final choreId = chore['id'] as String;
        final frequency = chore['frequency'] as String?;
        if (!isRecurring(frequency)) continue;

        // Check if there's already a pending/in_progress assignment
        final pendingAssignments = await _client
            .from('chore_assignments')
            .select('id')
            .eq('chore_id', choreId)
            .inFilter('status', ['pending', 'in_progress']);

        if ((pendingAssignments as List).isNotEmpty) continue;

        // Get the most recent completed assignment
        final lastCompleted = await _client
            .from('chore_assignments')
            .select()
            .eq('chore_id', choreId)
            .eq('status', 'completed')
            .order('completed_at', ascending: false)
            .limit(1);

        if ((lastCompleted as List).isEmpty) continue;

        final lastAssignment = lastCompleted.first;

        // Generate next instance
        final result = await onChoreCompleted(
          choreId: choreId,
          assignmentId: lastAssignment['id'] as String,
          householdId: householdId,
        );

        if (result != null) generated++;
      }

      debugLog('🔄 Recurring processing done: $generated new instances');
      return generated;
    } catch (e) {
      debugLog('❌ Error processing recurring chores: $e');
      return 0;
    }
  }

  // ── Queries ─────────────────────────────────────────────────────────

  /// Get all recurring chore templates for a household.
  Future<List<Map<String, dynamic>>> getRecurringTemplates(
    String householdId,
  ) async {
    try {
      final response = await _client
          .from('chores')
          .select('*, chore_assignments(id, status, due_date, assigned_to)')
          .eq('household_id', householdId)
          .eq('is_recurring', true)
          .isFilter('recurrence_parent_id', null) // only root templates
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugLog('❌ Error fetching recurring templates: $e');
      return [];
    }
  }

  /// Pause a recurring chore (stop generating new instances).
  Future<void> pauseRecurring(String choreId) async {
    await _client
        .from('chores')
        .update({'is_recurring': false})
        .eq('id', choreId);
  }

  /// Resume a recurring chore.
  Future<void> resumeRecurring(String choreId) async {
    await _client
        .from('chores')
        .update({'is_recurring': true})
        .eq('id', choreId);
  }

  /// Delete a recurring chore and optionally all future instances.
  Future<void> deleteRecurring(
    String choreId, {
    bool deleteFutureInstances = true,
  }) async {
    if (deleteFutureInstances) {
      // Find all child instances that are pending/in_progress
      final children = await _client
          .from('chores')
          .select('id')
          .eq('recurrence_parent_id', choreId);

      for (final child in children as List) {
        final childId = child['id'] as String;
        // Delete assignments first
        await _client
            .from('chore_assignments')
            .delete()
            .eq('chore_id', childId)
            .inFilter('status', ['pending', 'in_progress']);
        // Delete the chore if no completed assignments remain
        final remaining = await _client
            .from('chore_assignments')
            .select('id')
            .eq('chore_id', childId);
        if ((remaining as List).isEmpty) {
          await _client.from('chores').delete().eq('id', childId);
        }
      }
    }

    // Delete the template itself
    await _client.from('chore_assignments').delete().eq('chore_id', choreId);
    await _client.from('chores').delete().eq('id', choreId);
  }
}
