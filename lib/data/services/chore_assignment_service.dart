// lib/data/services/chore_assignment_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/user_preferences_model.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/repositories/user_preferences_repository.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'dart:math';

/// Result of an auto-assignment recommendation.
class AssignmentRecommendation {
  final String userId;
  final int score;
  final List<String> reasons;

  AssignmentRecommendation({
    required this.userId,
    required this.score,
    required this.reasons,
  });
}

/// Automatic chore assignment using weighted scoring.
///
/// Scoring factors (100 points max):
/// - Availability (25): Is the member free on the due date?
/// - Chore Preference (20): Does the member like this type of chore?
/// - Workload Balance (20): Is the member under their weekly limit?
/// - Fairness / History (20): Has the member done this chore recently?
/// - Exam Period (10): Is the member currently in exams?
/// - Weekend Preference (5): Does the chore match weekend habits?
class ChoreAssignmentService {
  final SupabaseClient _client = Supabase.instance.client;
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  // ── Chore type mapping ──────────────────────────────────────────────
  // Maps keywords in chore names to the canonical type keys stored in
  // user_preferences (preferred_chore_types / disliked_chore_types).

  static const Map<String, List<String>> _choreTypeKeywords = {
    'kitchen_cleaning': ['kitchen', 'cook', 'stove', 'counter', 'wipe'],
    'bathroom_cleaning': ['bathroom', 'toilet', 'shower', 'bath', 'sink'],
    'taking_out_trash': ['trash', 'garbage', 'rubbish', 'bin', 'waste'],
    'vacuuming': ['vacuum', 'hoover'],
    'mopping': ['mop', 'floor'],
    'grocery_shopping': ['grocery', 'groceries', 'shop', 'shopping', 'buy'],
    'dishwashing': ['dish', 'dishes', 'dishwash', 'plates', 'cutlery'],
    'restocking_supplies': ['restock', 'supplies', 'supply', 'refill'],
  };

  /// Infer the canonical chore type from a free-text chore name.
  /// Returns `null` if no type can be matched.
  static String? inferChoreType(String choreName) {
    final lower = choreName.toLowerCase();
    for (final entry in _choreTypeKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // ── Main entry point ────────────────────────────────────────────────

  /// Returns the user-id of the best assignee, or `null` when no one fits.
  ///
  /// If [choreType] is provided it takes precedence over keyword detection.
  Future<String?> findBestAssignee({
    required String householdId,
    required String choreName,
    required DateTime dueDate,
    String? choreType,
  }) async {
    try {
      debugLog('🤖 Auto-assign: scoring members for "$choreName"');

      choreType ??= inferChoreType(choreName);
      debugLog('🏷️ Inferred chore type: ${choreType ?? "unknown"}');

      // Fetch all active members
      final members = await _client
          .from('household_members')
          .select('user_id')
          .eq('household_id', householdId)
          .eq('is_active', true);

      final memberIds =
          (members as List).map((m) => m['user_id'] as String).toList();

      if (memberIds.isEmpty) {
        debugLog('⚠️ No active members in household');
        return null;
      }

      // Fetch preferences for all members
      final preferencesMap =
          await _preferencesRepository.getHouseholdMemberPreferences(
        householdId,
      );

      // Fetch recent assignment counts (last 7 days)
      final recentCounts =
          await getRecentAssignmentCounts(householdId, days: 7);

      // Fetch fairness data: who did this chore type most recently
      final lastAssigned = choreType != null
          ? await _getLastAssignedForChoreType(householdId, choreName)
          : <String, DateTime>{};

      // Score each member
      final scores = <String, int>{};

      for (final userId in memberIds) {
        final prefs = preferencesMap[userId] ??
            UserPreferences(userId: userId);

        // ── Hard constraints ──────────────────────────────────────
        if (_isHardSkip(prefs, dueDate)) {
          debugLog('⛔ $userId skipped (hard constraint)');
          continue;
        }

        final score = _scoreMember(
          userId: userId,
          prefs: prefs,
          choreType: choreType,
          dueDate: dueDate,
          weeklyCount: recentCounts[userId] ?? 0,
          lastAssignedDate: lastAssigned[userId],
        );

        debugLog('📊 $userId → $score pts');
        scores[userId] = score;
      }

      if (scores.isEmpty) {
        debugLog('⚠️ All members skipped — manual assignment needed');
        return null;
      }

      // Sort descending by score
      final sorted = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Handle ties: pick randomly among top scorers
      final topScore = sorted.first.value;
      final topCandidates =
          sorted.where((e) => e.value == topScore).map((e) => e.key).toList();

      final winner =
          topCandidates[Random().nextInt(topCandidates.length)];

      debugLog('🏆 Best assignee: $winner ($topScore pts)');
      return winner;
    } catch (e) {
      debugLog('❌ Auto-assign error: $e');
      return null;
    }
  }

  /// Like [findBestAssignee] but returns a full [AssignmentRecommendation]
  /// with human-readable reasons explaining why this person was picked.
  Future<AssignmentRecommendation?> getRecommendation({
    required String householdId,
    required String choreName,
    required DateTime dueDate,
    String? choreType,
  }) async {
    try {
      choreType ??= inferChoreType(choreName);

      final members = await _client
          .from('household_members')
          .select('user_id')
          .eq('household_id', householdId)
          .eq('is_active', true);

      final memberIds =
          (members as List).map((m) => m['user_id'] as String).toList();

      if (memberIds.isEmpty) return null;

      final preferencesMap =
          await _preferencesRepository.getHouseholdMemberPreferences(
        householdId,
      );
      final recentCounts =
          await getRecentAssignmentCounts(householdId, days: 7);
      final lastAssigned = choreType != null
          ? await _getLastAssignedForChoreType(householdId, choreName)
          : <String, DateTime>{};

      String? bestUserId;
      int bestScore = -1;
      List<String> bestReasons = [];

      for (final userId in memberIds) {
        final prefs =
            preferencesMap[userId] ?? UserPreferences(userId: userId);

        if (_isHardSkip(prefs, dueDate)) continue;

        final weeklyCount = recentCounts[userId] ?? 0;
        final lastDate = lastAssigned[userId];

        final score = _scoreMember(
          userId: userId,
          prefs: prefs,
          choreType: choreType,
          dueDate: dueDate,
          weeklyCount: weeklyCount,
          lastAssignedDate: lastDate,
        );

        if (score > bestScore) {
          bestScore = score;
          bestUserId = userId;
          bestReasons = _buildReasons(
            prefs: prefs,
            choreType: choreType,
            dueDate: dueDate,
            weeklyCount: weeklyCount,
            lastAssignedDate: lastDate,
          );
        }
      }

      if (bestUserId == null) return null;

      return AssignmentRecommendation(
        userId: bestUserId,
        score: bestScore,
        reasons: bestReasons,
      );
    } catch (e) {
      debugLog('❌ Recommendation error: $e');
      return null;
    }
  }

  /// Build human-readable reason chips for why a member was recommended.
  List<String> _buildReasons({
    required UserPreferences prefs,
    required String? choreType,
    required DateTime dueDate,
    required int weeklyCount,
    required DateTime? lastAssignedDate,
  }) {
    final reasons = <String>[];
    final dayName = _dayName(dueDate.weekday);

    // Availability
    if (prefs.availableDays.contains(dayName)) {
      reasons.add('Available');
    }

    // Preference
    if (choreType != null && prefs.preferredChoreTypes.contains(choreType)) {
      reasons.add('Prefers this chore');
    }

    // Workload
    final remaining = prefs.maxChoresPerWeek - weeklyCount;
    if (remaining > 0) {
      reasons.add('Light workload ($remaining slots left)');
    }

    // Fairness
    if (lastAssignedDate == null) {
      reasons.add('Hasn\'t done this before');
    } else {
      final days = DateTime.now().difference(lastAssignedDate).inDays;
      if (days >= 7) {
        reasons.add('Last did this ${days}d ago');
      }
    }

    // Exam
    final now = DateTime.now();
    final inExam = prefs.examPeriods.any(
      (ep) => now.isAfter(ep.start) && now.isBefore(ep.end),
    );
    if (!inExam) {
      reasons.add('No exams');
    }

    return reasons;
  }

  // ── Hard constraint check ───────────────────────────────────────────

  bool _isHardSkip(UserPreferences prefs, DateTime dueDate) {
    final dayName = _dayName(dueDate.weekday);
    final isWeekend = dueDate.weekday == 6 || dueDate.weekday == 7;

    // Goes home on weekends and due date is a weekend
    if (prefs.goHomeWeekends && isWeekend) return true;

    // Already at max chores — treated as hard skip
    // (we check this in scoring too, but 0 workload points effectively skips)
    return false;
  }

  // ── Scoring ─────────────────────────────────────────────────────────

  int _scoreMember({
    required String userId,
    required UserPreferences prefs,
    required String? choreType,
    required DateTime dueDate,
    required int weeklyCount,
    required DateTime? lastAssignedDate,
  }) {
    int score = 0;

    // 1. Availability (25 pts)
    score += _scoreAvailability(prefs, dueDate);

    // 2. Chore Preference (20 pts)
    score += _scorePreference(prefs, choreType);

    // 3. Workload Balance (20 pts)
    score += _scoreWorkload(prefs, weeklyCount);

    // 4. Fairness / History (20 pts)
    score += _scoreFairness(lastAssignedDate);

    // 5. Exam Period (10 pts)
    score += _scoreExamPeriod(prefs);

    // 6. Weekend Preference (5 pts)
    score += _scoreWeekend(prefs, dueDate);

    return score;
  }

  /// Availability: +25 if available on due date's day, 0 if not.
  int _scoreAvailability(UserPreferences prefs, DateTime dueDate) {
    final dayName = _dayName(dueDate.weekday);
    return prefs.availableDays.contains(dayName) ? 25 : 0;
  }

  /// Chore Preference: +20 preferred, +10 neutral, 0 disliked.
  int _scorePreference(UserPreferences prefs, String? choreType) {
    if (choreType == null) return 10; // unknown type → neutral
    if (prefs.preferredChoreTypes.contains(choreType)) return 20;
    if (prefs.dislikedChoreTypes.contains(choreType)) return 0;
    return 10; // neutral
  }

  /// Workload Balance: 0–20, scales linearly from max to 0.
  int _scoreWorkload(UserPreferences prefs, int weeklyCount) {
    final max = prefs.maxChoresPerWeek;
    if (weeklyCount >= max) return 0;
    // Linear scale: full marks when 0 chores, 0 when at max
    return ((1 - weeklyCount / max) * 20).round();
  }

  /// Fairness: +20 if never done / >14 days, down to +5 if done yesterday.
  int _scoreFairness(DateTime? lastAssigned) {
    if (lastAssigned == null) return 20; // never done → max fairness
    final daysSince = DateTime.now().difference(lastAssigned).inDays;
    if (daysSince >= 14) return 20;
    if (daysSince >= 7) return 15;
    if (daysSince >= 3) return 10;
    return 5; // done very recently
  }

  /// Exam Period: +10 not in exams, +5 in exams but under 50% load, 0 otherwise.
  int _scoreExamPeriod(UserPreferences prefs) {
    final now = DateTime.now();
    final inExam = prefs.examPeriods.any(
      (ep) => now.isAfter(ep.start) && now.isBefore(ep.end),
    );
    if (!inExam) return 10;
    // In exam — give partial credit if they still have capacity
    // (We don't have exact load here, but we can be lenient)
    return 5;
  }

  /// Weekend Preference: +5 if weekend chore matches their preference.
  int _scoreWeekend(UserPreferences prefs, DateTime dueDate) {
    final isWeekend = dueDate.weekday == 6 || dueDate.weekday == 7;
    if (!isWeekend) return 3; // weekday — neutral-ish
    if (prefs.goHomeWeekends) return 0; // shouldn't reach here (hard skip)
    return prefs.preferWeekendChores ? 5 : 2;
  }

  // ── Data helpers ────────────────────────────────────────────────────

  /// Count how many chore assignments each member got in the last [days] days.
  Future<Map<String, int>> getRecentAssignmentCounts(
    String householdId, {
    int days = 7,
  }) async {
    try {
      final since =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();

      final response = await _client
          .from('chore_assignments')
          .select('assigned_to, chores!inner(household_id)')
          .eq('chores.household_id', householdId)
          .gte('created_at', since);

      final counts = <String, int>{};
      for (final row in response as List) {
        final userId = row['assigned_to'] as String;
        counts[userId] = (counts[userId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugLog('⚠️ Could not fetch assignment counts: $e');
      return {};
    }
  }

  /// For each member, find when they were last assigned a chore whose name
  /// matches (used for fairness scoring).
  Future<Map<String, DateTime>> _getLastAssignedForChoreType(
    String householdId,
    String choreName,
  ) async {
    try {
      // We match on the chore name directly since that's what we have.
      // A more robust approach would use a `chore_type` column.
      final response = await _client
          .from('chore_assignments')
          .select('assigned_to, created_at, chores!inner(name, household_id)')
          .eq('chores.household_id', householdId)
          .order('created_at', ascending: false);

      final choreType = inferChoreType(choreName);
      final result = <String, DateTime>{};

      for (final row in response as List) {
        final userId = row['assigned_to'] as String;
        if (result.containsKey(userId)) continue; // already have most recent

        final rowChoreName = row['chores']['name'] as String;
        final rowType = inferChoreType(rowChoreName);

        if (choreType != null && rowType == choreType) {
          result[userId] = DateTime.parse(row['created_at'] as String);
        }
      }

      return result;
    } catch (e) {
      debugLog('⚠️ Could not fetch assignment history: $e');
      return {};
    }
  }

  // ── Room-aware helpers ────────────────────────────────────────────

  /// Fetch the household model (with room config) for a household.
  Future<HouseholdModel?> fetchHousehold(String householdId) async {
    try {
      final response =
          await _client
              .from('households')
              .select()
              .eq('id', householdId)
              .single();
      return HouseholdModel.fromJson(response);
    } catch (e) {
      debugLog('⚠️ Could not fetch household model: $e');
      return null;
    }
  }

  /// Map a chore type to the relevant room count.
  /// Returns null if the chore type isn't room-specific.
  static int? roomCountForChoreType(HouseholdModel household, String? choreType) {
    if (choreType == null) return null;
    switch (choreType) {
      case 'kitchen_cleaning':
        return household.numKitchens;
      case 'bathroom_cleaning':
        return household.numBathrooms;
      case 'vacuuming':
      case 'mopping':
        // These apply to all rooms
        return household.totalRooms;
      default:
        return null;
    }
  }

  /// Generate chore suggestions based on room configuration.
  /// Returns a list of chore name suggestions.
  static List<String> generateRoomChores(HouseholdModel household) {
    final chores = <String>[];

    // Bathrooms
    if (household.numBathrooms == 1) {
      chores.add('Clean Bathroom');
    } else {
      for (int i = 1; i <= household.numBathrooms; i++) {
        chores.add('Clean Bathroom $i');
      }
    }

    // Kitchens
    if (household.numKitchens == 1) {
      chores.add('Clean Kitchen');
    } else {
      for (int i = 1; i <= household.numKitchens; i++) {
        chores.add('Clean Kitchen $i');
      }
    }

    // Living rooms
    if (household.numLivingRooms == 1) {
      chores.add('Clean Living Room');
    } else {
      for (int i = 1; i <= household.numLivingRooms; i++) {
        chores.add('Clean Living Area $i');
      }
    }

    // General chores that scale with room count
    chores.add('Take Out Trash');
    chores.add('Vacuum Common Areas');
    chores.add('Mop Floors');
    chores.add('Grocery Shopping');
    chores.add('Wash Dishes');

    return chores;
  }

  // ── Utilities ───────────────────────────────────────────────────────

  static String _dayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }
}
