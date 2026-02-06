// lib/core/utils/auth_guard.dart
// Authentication and authorization guard utilities.
// Use these helpers to verify user permissions before sensitive operations.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

/// Provides authentication and authorization checking utilities.
///
/// **Security Note:** These are client-side convenience checks.
/// Server-side RLS policies are the authoritative security layer.
/// Always ensure RLS is properly configured in Supabase.
class AuthGuard {
  static final SupabaseClient _client = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATION CHECKS
  // ═══════════════════════════════════════════════════════════════

  /// Returns true if a user is currently authenticated.
  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Returns the current user's ID, or null if not authenticated.
  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Throws an exception if the user is not authenticated.
  /// Use this at the start of methods that require authentication.
  static void requireAuthentication() {
    if (!isAuthenticated()) {
      throw AuthGuardException('User must be authenticated to perform this action');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HOUSEHOLD MEMBERSHIP CHECKS
  // ═══════════════════════════════════════════════════════════════

  /// Checks if the current user is an active member of the specified household.
  ///
  /// Returns `true` if the user is an active member, `false` otherwise.
  static Future<bool> isHouseholdMember(String householdId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final response = await _client
          .from('household_members')
          .select('id')
          .eq('household_id', householdId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugLog('AuthGuard.isHouseholdMember error: $e');
      return false;
    }
  }

  /// Throws an exception if the user is not a member of the specified household.
  static Future<void> requireHouseholdMembership(String householdId) async {
    requireAuthentication();
    
    final isMember = await isHouseholdMember(householdId);
    if (!isMember) {
      throw AuthGuardException('User is not a member of this household');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMIN ROLE CHECKS
  // ═══════════════════════════════════════════════════════════════

  /// Checks if the current user is an admin of the specified household.
  ///
  /// Returns `true` if the user is an active admin, `false` otherwise.
  static Future<bool> isHouseholdAdmin(String householdId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final response = await _client
          .from('household_members')
          .select('role')
          .eq('household_id', householdId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response?['role'] == 'admin';
    } catch (e) {
      debugLog('AuthGuard.isHouseholdAdmin error: $e');
      return false;
    }
  }

  /// Throws an exception if the user is not an admin of the specified household.
  static Future<void> requireHouseholdAdmin(String householdId) async {
    requireAuthentication();
    
    final isAdmin = await isHouseholdAdmin(householdId);
    if (!isAdmin) {
      throw AuthGuardException('User must be a household admin to perform this action');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // OWNERSHIP CHECKS
  // ═══════════════════════════════════════════════════════════════

  /// Checks if the current user owns a specific resource.
  /// Useful for verifying if a user can modify their own data.
  static bool isOwner(String resourceOwnerId) {
    final userId = getCurrentUserId();
    return userId != null && userId == resourceOwnerId;
  }

  /// Throws an exception if the current user doesn't own the resource.
  static void requireOwnership(String resourceOwnerId) {
    requireAuthentication();
    
    if (!isOwner(resourceOwnerId)) {
      throw AuthGuardException('User does not own this resource');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // COMBINED CHECKS (Owner OR Admin)
  // ═══════════════════════════════════════════════════════════════

  /// Checks if user is either the owner of a resource or a household admin.
  /// Useful for operations like editing/deleting where either should be allowed.
  static Future<bool> isOwnerOrAdmin({
    required String resourceOwnerId,
    required String householdId,
  }) async {
    if (isOwner(resourceOwnerId)) return true;
    return await isHouseholdAdmin(householdId);
  }

  /// Throws if user is neither the owner nor a household admin.
  static Future<void> requireOwnerOrAdmin({
    required String resourceOwnerId,
    required String householdId,
  }) async {
    requireAuthentication();
    
    final hasPermission = await isOwnerOrAdmin(
      resourceOwnerId: resourceOwnerId,
      householdId: householdId,
    );
    
    if (!hasPermission) {
      throw AuthGuardException(
        'User must be the resource owner or a household admin',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SESSION VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Checks if the current session is still valid (not expired).
  static bool hasValidSession() {
    final session = _client.auth.currentSession;
    if (session == null) return false;

    // Check if token is expired
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isBefore(expiryTime);
  }

  /// Attempts to refresh the session if it's close to expiring.
  /// Call this before sensitive operations.
  static Future<bool> ensureValidSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      // If session expires in less than 5 minutes, refresh it
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
        
        if (expiryTime.isBefore(fiveMinutesFromNow)) {
          debugLog('AuthGuard: Session expiring soon, refreshing...');
          await _client.auth.refreshSession();
        }
      }

      return hasValidSession();
    } catch (e) {
      debugLog('AuthGuard.ensureValidSession error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BATCH PERMISSION CHECK
  // ═══════════════════════════════════════════════════════════════

  /// Checks multiple household memberships at once.
  /// Returns a map of householdId -> isMember.
  static Future<Map<String, bool>> checkMultipleMemberships(
    List<String> householdIds,
  ) async {
    final result = <String, bool>{};
    final userId = getCurrentUserId();
    
    if (userId == null) {
      for (final id in householdIds) {
        result[id] = false;
      }
      return result;
    }

    try {
      final response = await _client
          .from('household_members')
          .select('household_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .inFilter('household_id', householdIds);

      final memberHouseholds = (response as List)
          .map((r) => r['household_id'] as String)
          .toSet();

      for (final id in householdIds) {
        result[id] = memberHouseholds.contains(id);
      }
    } catch (e) {
      debugLog('AuthGuard.checkMultipleMemberships error: $e');
      for (final id in householdIds) {
        result[id] = false;
      }
    }

    return result;
  }
}

/// Exception thrown when an auth guard check fails.
class AuthGuardException implements Exception {
  final String message;

  AuthGuardException(this.message);

  @override
  String toString() => 'AuthGuardException: $message';
}
