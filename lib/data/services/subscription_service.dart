// lib/data/services/subscription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/core/config/subscription_config.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Tier lookup ───────────────────────────────────────────────

  /// Returns the effective tier (falls back to free if expired).
  Future<SubscriptionTier> getHouseholdTier(String householdId) async {
    try {
      final response = await _supabase
          .from('households')
          .select('subscription_tier, subscription_expires_at')
          .eq('id', householdId)
          .single();

      final tierStr = response['subscription_tier'] as String? ?? 'free';
      final expiresAt = response['subscription_expires_at'] as String?;

      // Expired → free
      if (expiresAt != null &&
          DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        return SubscriptionTier.free;
      }

      return SubscriptionTier.values.firstWhere(
        (t) => t.name == tierStr,
        orElse: () => SubscriptionTier.free,
      );
    } catch (e) {
      debugLog('❌ SubscriptionService.getHouseholdTier: $e');
      return SubscriptionTier.free;
    }
  }

  // ── Limit checks ─────────────────────────────────────────────

  Future<bool> canAddMember(String householdId) async {
    final tier = await getHouseholdTier(householdId);
    final count = await _getMemberCount(householdId);
    return count < tier.maxMembers;
  }

  Future<bool> canAddChore(String householdId) async {
    final tier = await getHouseholdTier(householdId);
    final count = await _getActiveChoreCount(householdId);
    return count < tier.maxActiveChores;
  }

  Future<bool> canAddRecurringChore(String householdId) async {
    final tier = await getHouseholdTier(householdId);
    final count = await _getRecurringChoreCount(householdId);
    return count < tier.maxRecurringChores;
  }

  // ── Usage summary ─────────────────────────────────────────────

  Future<SubscriptionUsage> getUsage(String householdId) async {
    final tier = await getHouseholdTier(householdId);
    final members = await _getMemberCount(householdId);
    final chores = await _getActiveChoreCount(householdId);
    final recurring = await _getRecurringChoreCount(householdId);

    return SubscriptionUsage(
      tier: tier,
      memberCount: members,
      memberLimit: tier.maxMembers,
      choreCount: chores,
      choreLimit: tier.maxActiveChores,
      recurringCount: recurring,
      recurringLimit: tier.maxRecurringChores,
    );
  }

  // ── Internal queries ──────────────────────────────────────────

  Future<int> _getMemberCount(String householdId) async {
    try {
      final res = await _supabase
          .from('household_members')
          .select('id')
          .eq('household_id', householdId)
          .eq('is_active', true);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getActiveChoreCount(String householdId) async {
    try {
      final res = await _supabase
          .from('chores')
          .select('id')
          .eq('household_id', householdId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getRecurringChoreCount(String householdId) async {
    try {
      final res = await _supabase
          .from('chores')
          .select('id')
          .eq('household_id', householdId)
          .eq('is_recurring', true);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ── Manual upgrade (for testing / admin override) ─────────────

  Future<void> upgradeHousehold(
    String householdId,
    SubscriptionTier tier, {
    int months = 1,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('households').update({
      'subscription_tier': tier.name,
      'subscription_owner_id': userId,
      'subscription_started_at': DateTime.now().toIso8601String(),
      'subscription_expires_at':
          DateTime.now().add(Duration(days: 30 * months)).toIso8601String(),
      'subscription_platform': 'manual',
    }).eq('id', householdId);
  }
}

// ── Usage model ───────────────────────────────────────────────────

class SubscriptionUsage {
  final SubscriptionTier tier;
  final int memberCount;
  final int memberLimit;
  final int choreCount;
  final int choreLimit;
  final int recurringCount;
  final int recurringLimit;

  SubscriptionUsage({
    required this.tier,
    required this.memberCount,
    required this.memberLimit,
    required this.choreCount,
    required this.choreLimit,
    required this.recurringCount,
    required this.recurringLimit,
  });

  bool get isAtMemberLimit => memberCount >= memberLimit;
  bool get isAtChoreLimit => choreCount >= choreLimit;
  bool get isAtRecurringLimit => recurringCount >= recurringLimit;
  bool get isAtAnyLimit => isAtMemberLimit || isAtChoreLimit || isAtRecurringLimit;

  double get memberUsagePercent =>
      memberLimit > 0 ? memberCount / memberLimit : 0;
  double get choreUsagePercent =>
      choreLimit > 0 ? choreCount / choreLimit : 0;
  double get recurringUsagePercent =>
      recurringLimit > 0 ? recurringCount / recurringLimit : 0;
}
