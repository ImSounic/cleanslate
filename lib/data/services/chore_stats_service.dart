// lib/data/services/chore_stats_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

class MemberStats {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final int completedCount;

  MemberStats({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.completedCount,
  });
}

class PersonalStats {
  final int totalCompleted;
  final int currentStreak;
  final String? mostCommonType;
  final int thisWeekCount;
  final int thisMonthCount;

  PersonalStats({
    required this.totalCompleted,
    required this.currentStreak,
    this.mostCommonType,
    required this.thisWeekCount,
    required this.thisMonthCount,
  });
}

class ChoreStatsService {
  final _client = Supabase.instance.client;

  /// Get completed chore counts per member for a date range.
  Future<List<MemberStats>> getMemberStats(
    String householdId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // Query assignments joined with chores (for household filter) and profiles
      var query = _client
          .from('chore_assignments')
          .select('assigned_to, profiles!inner(id, full_name, profile_image_url), chores!inner(household_id)')
          .eq('status', 'completed')
          .eq('chores.household_id', householdId);

      if (from != null) {
        query = query.gte('updated_at', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('updated_at', to.toIso8601String());
      }

      final data = await query;

      // Aggregate counts per user
      final Map<String, MemberStats> statsMap = {};
      for (final row in data) {
        final userId = row['assigned_to'] as String;
        final profile = row['profiles'] as Map<String, dynamic>;
        if (statsMap.containsKey(userId)) {
          statsMap[userId] = MemberStats(
            userId: userId,
            name: statsMap[userId]!.name,
            profileImageUrl: statsMap[userId]!.profileImageUrl,
            completedCount: statsMap[userId]!.completedCount + 1,
          );
        } else {
          statsMap[userId] = MemberStats(
            userId: userId,
            name: profile['full_name'] ?? 'Unknown',
            profileImageUrl: profile['profile_image_url'] as String?,
            completedCount: 1,
          );
        }
      }

      final result = statsMap.values.toList();
      result.sort((a, b) => b.completedCount.compareTo(a.completedCount));
      return result;
    } catch (e) {
      debugLog('ChoreStatsService.getMemberStats error: $e');
      return [];
    }
  }

  /// Get personal stats for the current user in a household.
  Future<PersonalStats> getPersonalStats(String householdId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return PersonalStats(
          totalCompleted: 0,
          currentStreak: 0,
          thisWeekCount: 0,
          thisMonthCount: 0,
        );
      }

      // All completed assignments for this user in this household
      final allCompleted = await _client
          .from('chore_assignments')
          .select('id, updated_at, chores!inner(household_id, chore_type)')
          .eq('assigned_to', userId)
          .eq('status', 'completed')
          .eq('chores.household_id', householdId)
          .order('updated_at', ascending: false);

      final totalCompleted = allCompleted.length;

      // This week
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final thisWeekCount = allCompleted.where((r) {
        final d = DateTime.tryParse(r['updated_at'] ?? '');
        return d != null && d.isAfter(weekStartDate);
      }).length;

      // This month
      final monthStart = DateTime(now.year, now.month, 1);
      final thisMonthCount = allCompleted.where((r) {
        final d = DateTime.tryParse(r['updated_at'] ?? '');
        return d != null && d.isAfter(monthStart);
      }).length;

      // Current streak — consecutive days with at least one completed chore
      int currentStreak = 0;
      if (allCompleted.isNotEmpty) {
        // Collect unique dates (day only)
        final Set<String> completedDates = {};
        for (final row in allCompleted) {
          final d = DateTime.tryParse(row['updated_at'] ?? '');
          if (d != null) {
            completedDates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
          }
        }

        // Walk backwards from today
        var checkDate = DateTime(now.year, now.month, now.day);
        // If today has no completion, start from yesterday
        final todayStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (!completedDates.contains(todayStr)) {
          checkDate = checkDate.subtract(const Duration(days: 1));
        }

        while (true) {
          final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          if (completedDates.contains(dateStr)) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      // Most common chore type
      String? mostCommonType;
      final Map<String, int> typeCounts = {};
      for (final row in allCompleted) {
        final chore = row['chores'] as Map<String, dynamic>;
        final type = chore['chore_type'] as String?;
        if (type != null && type.isNotEmpty) {
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }
      if (typeCounts.isNotEmpty) {
        mostCommonType = typeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }

      return PersonalStats(
        totalCompleted: totalCompleted,
        currentStreak: currentStreak,
        mostCommonType: mostCommonType,
        thisWeekCount: thisWeekCount,
        thisMonthCount: thisMonthCount,
      );
    } catch (e) {
      debugLog('ChoreStatsService.getPersonalStats error: $e');
      return PersonalStats(
        totalCompleted: 0,
        currentStreak: 0,
        thisWeekCount: 0,
        thisMonthCount: 0,
      );
    }
  }

  /// Get chore type distribution for the household.
  Future<Map<String, int>> getChoreTypeDistribution(
    String householdId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      var query = _client
          .from('chore_assignments')
          .select('id, chores!inner(household_id, chore_type)')
          .eq('status', 'completed')
          .eq('chores.household_id', householdId);

      if (from != null) {
        query = query.gte('updated_at', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('updated_at', to.toIso8601String());
      }

      final data = await query;

      final Map<String, int> distribution = {};
      for (final row in data) {
        final chore = row['chores'] as Map<String, dynamic>;
        final type = (chore['chore_type'] as String?) ?? 'Other';
        distribution[type] = (distribution[type] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugLog('ChoreStatsService.getChoreTypeDistribution error: $e');
      return {};
    }
  }
}
