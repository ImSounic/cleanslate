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

/// ═══════════════════════════════════════════════════════════════════════════
/// ROTATION-FIRST AUTO-ASSIGNMENT ALGORITHM
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Core Principle: ROTATION IS MANDATORY, PREFERENCES ARE TIEBREAKERS.
/// 
/// Priority order (highest to lowest):
/// 1. ROTATION (50 pts): Who hasn't done this chore TYPE recently?
/// 2. FAIRNESS (25 pts): Who has the lowest total chore count?
/// 3. AVAILABILITY (15 pts): Is the member free on the due date?
/// 4. PREFERENCE (10 pts): What's their 1-5 rating for this chore? (tiebreaker)
/// 
/// Key behaviors:
/// - Everyone does every chore type over time, regardless of preferences
/// - Preferences only influence who goes next when rotation is equal
/// - New members go to front of queue (haven't done anything)
/// - Even if someone rates a chore 5, they won't always get it
/// - Even if someone rates a chore 1, they can't escape doing it
/// ═══════════════════════════════════════════════════════════════════════════

class ChoreAssignmentService {
  final SupabaseClient _client = Supabase.instance.client;
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  // ── Chore type mapping ──────────────────────────────────────────────
  // Maps keywords in chore names to the canonical type keys.

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

  // ══════════════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // ══════════════════════════════════════════════════════════════════════

  /// Returns the user-id of the best assignee using rotation-first logic.
  /// Returns `null` when no one fits.
  Future<String?> findBestAssignee({
    required String householdId,
    required String choreName,
    required DateTime dueDate,
    String? choreType,
  }) async {
    try {
      debugLog('🤖 Auto-assign: finding best member for "$choreName"');
      debugLog('📋 Algorithm: ROTATION-FIRST (preferences as tiebreaker only)');

      choreType ??= inferChoreType(choreName);
      debugLog('🏷️ Chore type: ${choreType ?? "unknown"}');

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

      debugLog('👥 Members to evaluate: ${memberIds.length}');

      // Fetch all data needed for scoring
      final preferencesMap =
          await _preferencesRepository.getHouseholdMemberPreferences(householdId);
      final totalChoreCount = await _getTotalChoreCountPerMember(householdId);
      final lastAssignedByType = await _getLastAssignedByChoreType(householdId, choreType);

      // Score each member
      final scores = <String, int>{};
      final scoreBreakdowns = <String, Map<String, int>>{};

      for (final userId in memberIds) {
        final prefs = preferencesMap[userId] ?? UserPreferences(userId: userId);

        // Check hard constraints
        if (_isHardSkip(prefs, dueDate)) {
          debugLog('⛔ $userId: SKIPPED (hard constraint - goes home weekends)');
          continue;
        }

        final breakdown = _scoreMemberRotationFirst(
          userId: userId,
          prefs: prefs,
          choreType: choreType,
          dueDate: dueDate,
          totalChoreCount: totalChoreCount[userId] ?? 0,
          lastAssignedDate: lastAssignedByType[userId],
          memberCount: memberIds.length,
        );

        final totalScore = breakdown.values.fold(0, (a, b) => a + b);
        scores[userId] = totalScore;
        scoreBreakdowns[userId] = breakdown;

        debugLog('📊 $userId: $totalScore pts (rotation:${breakdown['rotation']}, fairness:${breakdown['fairness']}, avail:${breakdown['availability']}, pref:${breakdown['preference']})');
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

      final winner = topCandidates[Random().nextInt(topCandidates.length)];

      debugLog('🏆 Winner: $winner ($topScore pts)');
      if (topCandidates.length > 1) {
        debugLog('   (chosen randomly from ${topCandidates.length} tied candidates)');
      }

      return winner;
    } catch (e) {
      debugLog('❌ Auto-assign error: $e');
      return null;
    }
  }

  /// Full recommendation with reasons.
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
          await _preferencesRepository.getHouseholdMemberPreferences(householdId);
      final totalChoreCount = await _getTotalChoreCountPerMember(householdId);
      final lastAssignedByType = await _getLastAssignedByChoreType(householdId, choreType);

      String? bestUserId;
      int bestScore = -1;
      List<String> bestReasons = [];

      for (final userId in memberIds) {
        final prefs = preferencesMap[userId] ?? UserPreferences(userId: userId);

        if (_isHardSkip(prefs, dueDate)) continue;

        final breakdown = _scoreMemberRotationFirst(
          userId: userId,
          prefs: prefs,
          choreType: choreType,
          dueDate: dueDate,
          totalChoreCount: totalChoreCount[userId] ?? 0,
          lastAssignedDate: lastAssignedByType[userId],
          memberCount: memberIds.length,
        );

        final score = breakdown.values.fold(0, (a, b) => a + b);

        if (score > bestScore) {
          bestScore = score;
          bestUserId = userId;
          bestReasons = _buildReasons(
            prefs: prefs,
            choreType: choreType,
            dueDate: dueDate,
            totalChoreCount: totalChoreCount[userId] ?? 0,
            lastAssignedDate: lastAssignedByType[userId],
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

  // ══════════════════════════════════════════════════════════════════════
  // ROTATION-FIRST SCORING (100 points max)
  // ══════════════════════════════════════════════════════════════════════

  Map<String, int> _scoreMemberRotationFirst({
    required String userId,
    required UserPreferences prefs,
    required String? choreType,
    required DateTime dueDate,
    required int totalChoreCount,
    required DateTime? lastAssignedDate,
    required int memberCount,
  }) {
    return {
      'rotation': _scoreRotation(lastAssignedDate),
      'fairness': _scoreFairness(totalChoreCount, memberCount),
      'availability': _scoreAvailability(prefs, dueDate),
      'preference': _scorePreference(prefs, choreType),
    };
  }

  /// ROTATION SCORE (50 pts) - HIGHEST PRIORITY
  /// 
  /// Who hasn't done this chore type recently?
  /// - Never done it: 50 pts (front of queue)
  /// - Did it 14+ days ago: 45 pts
  /// - Did it 7-13 days ago: 35 pts
  /// - Did it 3-6 days ago: 20 pts
  /// - Did it 1-2 days ago: 10 pts
  /// - Did it today: 5 pts
  int _scoreRotation(DateTime? lastAssigned) {
    if (lastAssigned == null) {
      return 50; // Never done → front of rotation queue
    }
    
    final daysSince = DateTime.now().difference(lastAssigned).inDays;
    
    if (daysSince >= 14) return 45;
    if (daysSince >= 7) return 35;
    if (daysSince >= 3) return 20;
    if (daysSince >= 1) return 10;
    return 5; // Did it today
  }

  /// FAIRNESS SCORE (25 pts) - MEDIUM PRIORITY
  /// 
  /// Who has the lowest total chore count?
  /// Uses relative comparison: member with fewest chores gets max points.
  int _scoreFairness(int memberChoreCount, int memberCount) {
    // Base fairness: fewer chores = higher score
    // Max 25 pts when member has done very few chores
    // We use inverse relationship: lower count = higher score
    
    if (memberChoreCount == 0) return 25; // New member or very few chores
    
    // Scale down based on chore count
    // At 10+ chores, gets minimum points
    final score = 25 - (memberChoreCount * 2).clamp(0, 20);
    return score.clamp(5, 25);
  }

  /// AVAILABILITY SCORE (15 pts) - MEDIUM-LOW PRIORITY
  /// 
  /// Is the member free on the due date?
  int _scoreAvailability(UserPreferences prefs, DateTime dueDate) {
    final dayName = _dayName(dueDate.weekday);
    
    if (prefs.availableDays.contains(dayName)) {
      return 15; // Available
    }
    return 5; // Not available but can still be assigned
  }

  /// PREFERENCE SCORE (10 pts) - LOWEST PRIORITY (TIEBREAKER ONLY)
  /// 
  /// What's their 1-5 rating for this chore type?
  /// Uses the new choreRatings map, with fallback to legacy arrays.
  /// 
  /// Rating 5: 10 pts
  /// Rating 4: 8 pts
  /// Rating 3: 6 pts (neutral)
  /// Rating 2: 4 pts
  /// Rating 1: 2 pts
  /// Unknown: 6 pts (neutral)
  int _scorePreference(UserPreferences prefs, String? choreType) {
    if (choreType == null) return 6; // Unknown type → neutral
    
    // Try new choreRatings first
    if (prefs.choreRatings.containsKey(choreType)) {
      final rating = prefs.choreRatings[choreType]!;
      return _ratingToPoints(rating);
    }
    
    // Fallback to legacy arrays
    if (prefs.preferredChoreTypes.contains(choreType)) {
      return 8; // Legacy preferred → treat as rating 4
    }
    if (prefs.dislikedChoreTypes.contains(choreType)) {
      return 4; // Legacy disliked → treat as rating 2
    }
    
    return 6; // Neutral (rating 3)
  }

  /// Convert 1-5 rating to preference points (2-10 pts)
  int _ratingToPoints(int rating) {
    switch (rating) {
      case 5: return 10;
      case 4: return 8;
      case 3: return 6;
      case 2: return 4;
      case 1: return 2;
      default: return 6; // Invalid rating → neutral
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // HARD CONSTRAINTS
  // ══════════════════════════════════════════════════════════════════════

  bool _isHardSkip(UserPreferences prefs, DateTime dueDate) {
    final isWeekend = dueDate.weekday == 6 || dueDate.weekday == 7;
    
    // Goes home on weekends and due date is a weekend
    if (prefs.goHomeWeekends && isWeekend) return true;
    
    // Check exam period - if in exam, reduce likelihood but don't skip
    // (We handle this in scoring now, not as hard skip)
    
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════
  // REASON BUILDER
  // ══════════════════════════════════════════════════════════════════════

  List<String> _buildReasons({
    required UserPreferences prefs,
    required String? choreType,
    required DateTime dueDate,
    required int totalChoreCount,
    required DateTime? lastAssignedDate,
  }) {
    final reasons = <String>[];
    final dayName = _dayName(dueDate.weekday);

    // Rotation reason (primary)
    if (lastAssignedDate == null) {
      reasons.add('Never done this chore type');
    } else {
      final days = DateTime.now().difference(lastAssignedDate).inDays;
      if (days >= 7) {
        reasons.add('Last did this ${days}d ago');
      } else if (days >= 1) {
        reasons.add('Due for rotation');
      }
    }

    // Fairness reason
    if (totalChoreCount == 0) {
      reasons.add('New member - no chores yet');
    } else if (totalChoreCount <= 3) {
      reasons.add('Light workload ($totalChoreCount total)');
    }

    // Availability
    if (prefs.availableDays.contains(dayName)) {
      reasons.add('Available');
    }

    // Preference (only mention if high)
    if (choreType != null) {
      final rating = prefs.choreRatings[choreType] ?? 
          (prefs.preferredChoreTypes.contains(choreType) ? 4 : 
           prefs.dislikedChoreTypes.contains(choreType) ? 2 : 3);
      if (rating >= 4) {
        reasons.add('Likes this chore');
      }
    }

    return reasons;
  }

  // ══════════════════════════════════════════════════════════════════════
  // DATA FETCHING
  // ══════════════════════════════════════════════════════════════════════

  /// Get TOTAL chore count per member (all time, for fairness calculation)
  Future<Map<String, int>> _getTotalChoreCountPerMember(String householdId) async {
    try {
      final response = await _client
          .from('chore_assignments')
          .select('assigned_to, chores!inner(household_id)')
          .eq('chores.household_id', householdId);

      final counts = <String, int>{};
      for (final row in response as List) {
        final userId = row['assigned_to'] as String;
        counts[userId] = (counts[userId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugLog('⚠️ Could not fetch total chore counts: $e');
      return {};
    }
  }

  /// Get last assignment date PER CHORE TYPE for each member.
  /// This is the key data for rotation tracking.
  Future<Map<String, DateTime>> _getLastAssignedByChoreType(
    String householdId,
    String? targetChoreType,
  ) async {
    try {
      if (targetChoreType == null) {
        // No type detected - just get most recent assignment of any type
        return _getLastAssignedAny(householdId);
      }

      final response = await _client
          .from('chore_assignments')
          .select('assigned_to, created_at, chores!inner(name, household_id)')
          .eq('chores.household_id', householdId)
          .order('created_at', ascending: false);

      final result = <String, DateTime>{};

      for (final row in response as List) {
        final userId = row['assigned_to'] as String;
        if (result.containsKey(userId)) continue; // Already have most recent for this user

        final choreName = row['chores']['name'] as String;
        final rowChoreType = inferChoreType(choreName);

        // Match by chore type
        if (rowChoreType == targetChoreType) {
          result[userId] = DateTime.parse(row['created_at'] as String);
        }
      }

      return result;
    } catch (e) {
      debugLog('⚠️ Could not fetch rotation history: $e');
      return {};
    }
  }

  /// Fallback: get last assignment of any chore per member
  Future<Map<String, DateTime>> _getLastAssignedAny(String householdId) async {
    try {
      final response = await _client
          .from('chore_assignments')
          .select('assigned_to, created_at, chores!inner(household_id)')
          .eq('chores.household_id', householdId)
          .order('created_at', ascending: false);

      final result = <String, DateTime>{};

      for (final row in response as List) {
        final userId = row['assigned_to'] as String;
        if (!result.containsKey(userId)) {
          result[userId] = DateTime.parse(row['created_at'] as String);
        }
      }

      return result;
    } catch (e) {
      debugLog('⚠️ Could not fetch assignment history: $e');
      return {};
    }
  }

  /// Count how many chore assignments each member got in the last [days] days.
  /// (Kept for backward compatibility)
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

  // ══════════════════════════════════════════════════════════════════════
  // ROOM-AWARE HELPERS (unchanged)
  // ══════════════════════════════════════════════════════════════════════

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

  static int? roomCountForChoreType(HouseholdModel household, String? choreType) {
    if (choreType == null) return null;
    switch (choreType) {
      case 'kitchen_cleaning':
        return household.numKitchens;
      case 'bathroom_cleaning':
        return household.numBathrooms;
      case 'vacuuming':
      case 'mopping':
        return household.totalRooms;
      default:
        return null;
    }
  }

  static List<String> generateRoomChores(HouseholdModel household) {
    final chores = <String>[];

    if (household.numBathrooms == 1) {
      chores.add('Clean Bathroom');
    } else {
      for (int i = 1; i <= household.numBathrooms; i++) {
        chores.add('Clean Bathroom $i');
      }
    }

    if (household.numKitchens == 1) {
      chores.add('Clean Kitchen');
    } else {
      for (int i = 1; i <= household.numKitchens; i++) {
        chores.add('Clean Kitchen $i');
      }
    }

    if (household.numLivingRooms == 1) {
      chores.add('Clean Living Room');
    } else {
      for (int i = 1; i <= household.numLivingRooms; i++) {
        chores.add('Clean Living Area $i');
      }
    }

    chores.add('Take Out Trash');
    chores.add('Vacuum Common Areas');
    chores.add('Mop Floors');
    chores.add('Grocery Shopping');
    chores.add('Wash Dishes');

    return chores;
  }

  // ══════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ══════════════════════════════════════════════════════════════════════

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
