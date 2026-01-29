// lib/data/repositories/household_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/models/household_member_model.dart';
import 'dart:math';

class HouseholdRepository {
  static final HouseholdRepository _instance = HouseholdRepository._internal();
  factory HouseholdRepository() => _instance;
  HouseholdRepository._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Cache for household members to reduce queries
  final Map<String, List<HouseholdMemberModel>> _membersCache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  // Helper method to generate household codes
  String _generateHouseholdCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Get all households for the current user with optimized query
  Future<List<HouseholdModel>> getUserHouseholds() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get households where user is an active member
      final response = await _client
          .from('household_members')
          .select('''
            household:households!inner(
              id,
              name,
              code,
              created_at,
              updated_at,
              created_by
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      return (response as List)
          .map((item) => HouseholdModel.fromJson(item['household']))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch households: $e');
    }
  }

  // Get all households for the current user (Map version for backward compatibility)
  Future<List<Map<String, dynamic>>> getHouseholds() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('household_members')
          .select('''
            household:households!inner(
              id,
              name,
              code,
              created_at,
              updated_at,
              created_by,
              household_members!inner(count)
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      // Transform the response to match expected format
      return (response as List).map((item) {
        final household = item['household'] as Map<String, dynamic>;
        // Add member count
        household['member_count'] =
            household['household_members']?[0]?['count'] ?? 0;
        return household;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch households: $e');
    }
  }

  // Get a single household by ID
  Future<HouseholdModel> getHouseholdModel(String householdId) async {
    try {
      // Validate input
      if (householdId.isEmpty) {
        throw Exception('Household ID cannot be empty');
      }

      final response =
          await _client
              .from('households')
              .select()
              .eq('id', householdId)
              .single();

      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch household: $e');
    }
  }

  // Get a single household by ID (Map version)
  Future<Map<String, dynamic>?> getHousehold(String householdId) async {
    try {
      if (householdId.isEmpty) {
        throw Exception('Household ID cannot be empty');
      }

      final response =
          await _client
              .from('households')
              .select('''
            *,
            household_members(count)
          ''')
              .eq('id', householdId)
              .single();

      // Add member count to response
      response['member_count'] =
          response['household_members']?[0]?['count'] ?? 0;

      return response;
    } catch (e) {
      throw Exception('Failed to fetch household: $e');
    }
  }

  // Create a new household with validation
  Future<HouseholdModel> createHousehold(String name) async {
    try {
      // Validate input
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Household name cannot be empty');
      }

      if (trimmedName.length > 100) {
        throw Exception('Household name is too long (max 100 characters)');
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate a unique code
      String code = _generateHouseholdCode();

      // Create household with the generated code
      final response =
          await _client
              .from('households')
              .insert({
                'name': trimmedName,
                'created_by': userId,
                'code': code, // Explicitly set the code
              })
              .select()
              .single();

      final household = HouseholdModel.fromJson(response);

      // Create the first household member record (creator as admin)
      await _client.from('household_members').insert({
        'household_id': household.id,
        'user_id': userId,
        'role': 'admin',
        'is_active': true,
      });

      // Clear cache since we have a new household
      _clearCache();

      return household;
    } catch (e) {
      throw Exception('Failed to create household: $e');
    }
  }

  // Join household using code with improved validation
  Future<HouseholdModel> joinHouseholdWithCode(String code) async {
    try {
      // Validate input
      final trimmedCode = code.trim().toUpperCase();
      if (trimmedCode.length != 8) {
        throw Exception('Invalid code format. Code must be 8 characters long.');
      }

      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmedCode)) {
        throw Exception(
          'Invalid code format. Code must contain only letters and numbers.',
        );
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Use the secure RPC function to find the household by code
      final householdResults = await _client.rpc(
        'find_household_by_code',
        params: {'search_code': trimmedCode},
      );

      if (householdResults == null || householdResults.isEmpty) {
        throw Exception(
          'No household found with this code. Please check and try again.',
        );
      }

      // Get the first matching household
      final householdResponse = householdResults[0];
      final householdId = householdResponse['id'] as String;

      // Check if user is already a member
      final existingMemberResults =
          await _client
              .from('household_members')
              .select()
              .eq('household_id', householdId)
              .eq('user_id', userId)
              .maybeSingle();

      if (existingMemberResults != null) {
        if (existingMemberResults['is_active'] == true) {
          throw Exception('You are already a member of this household');
        } else {
          // Reactivate membership
          await _client
              .from('household_members')
              .update({
                'is_active': true,
                'joined_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existingMemberResults['id']);
        }
      } else {
        // Add user as a new member
        await _client.from('household_members').insert({
          'household_id': householdId,
          'user_id': userId,
          'role': 'member',
          'is_active': true,
        });
      }

      // Clear cache for this household
      _membersCache.remove(householdId);

      return HouseholdModel.fromJson(householdResponse);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to join household: $e');
    }
  }

  // Get household members with fixed join syntax
  // In household_repository.dart, find the getHouseholdMembers method and replace it:
  Future<List<HouseholdMemberModel>> getHouseholdMembers(
    String householdId,
  ) async {
    try {
      if (householdId.isEmpty) {
        throw Exception('Household ID cannot be empty');
      }

      // Check cache first
      if (_shouldUseCache(householdId)) {
        return _membersCache[householdId]!;
      }

      // Fetch household members with profile data in a single query
      // using Supabase's foreign key join (replaces N+1 per-member queries)
      final membersResponse = await _client
          .from('household_members')
          .select('*, profiles!inner(full_name, email, profile_image_url)')
          .eq('household_id', householdId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      final members = <HouseholdMemberModel>[];

      for (final memberData in membersResponse) {
        final profile = memberData['profiles'] as Map<String, dynamic>?;

        members.add(
          HouseholdMemberModel(
            id: memberData['id'] as String,
            householdId: memberData['household_id'] as String,
            userId: memberData['user_id'] as String,
            role: memberData['role'] as String,
            joinedAt: DateTime.parse(memberData['joined_at'] as String),
            isActive: memberData['is_active'] as bool,
            fullName: profile?['full_name'] as String?,
            email: profile?['email'] as String? ?? 'Unknown',
            profileImageUrl: profile?['profile_image_url'] as String?,
          ),
        );
      }

      // Update cache
      _membersCache[householdId] = members;
      _lastCacheUpdate = DateTime.now();

      return members;
    } catch (e) {
      throw Exception('Failed to fetch household members: $e');
    }
  }

  // Update member role with validation
  Future<void> updateMemberRole(String memberId, String newRole) async {
    try {
      // Validate inputs
      if (memberId.isEmpty) {
        throw Exception('Member ID cannot be empty');
      }

      final validRoles = ['admin', 'member'];
      if (!validRoles.contains(newRole)) {
        throw Exception('Invalid role. Must be either "admin" or "member"');
      }

      // Ensure at least one admin remains
      if (newRole == 'member') {
        final member =
            await _client
                .from('household_members')
                .select('household_id')
                .eq('id', memberId)
                .single();

        final adminCount = await _client
            .from('household_members')
            .select('id')
            .eq('household_id', member['household_id'])
            .eq('role', 'admin')
            .eq('is_active', true);

        if (adminCount.length <= 1) {
          throw Exception('Cannot remove the last admin from the household');
        }
      }

      await _client
          .from('household_members')
          .update({'role': newRole})
          .eq('id', memberId);

      // Clear cache
      _clearCache();
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  // Remove member from household (soft delete)
  Future<void> removeMemberFromHousehold(String memberId) async {
    try {
      if (memberId.isEmpty) {
        throw Exception('Member ID cannot be empty');
      }

      // Get member details first
      final member =
          await _client
              .from('household_members')
              .select('household_id, role')
              .eq('id', memberId)
              .single();

      // Ensure at least one admin remains
      if (member['role'] == 'admin') {
        final adminCount = await _client
            .from('household_members')
            .select('id')
            .eq('household_id', member['household_id'])
            .eq('role', 'admin')
            .eq('is_active', true);

        if (adminCount.length <= 1) {
          throw Exception('Cannot remove the last admin from the household');
        }
      }

      await _client
          .from('household_members')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId);

      // Clear cache
      _clearCache();
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Update household details with validation
  Future<HouseholdModel> updateHousehold(
    String householdId, {
    required String name,
  }) async {
    try {
      // Validate inputs
      if (householdId.isEmpty) {
        throw Exception('Household ID cannot be empty');
      }

      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Household name cannot be empty');
      }

      if (trimmedName.length > 100) {
        throw Exception('Household name is too long (max 100 characters)');
      }

      final response =
          await _client
              .from('households')
              .update({
                'name': trimmedName,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', householdId)
              .select()
              .single();

      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update household: $e');
    }
  }

  // Delete household with proper cleanup
  Future<void> deleteHousehold(String householdId) async {
    try {
      if (householdId.isEmpty) {
        throw Exception('Household ID cannot be empty');
      }

      // Note: This should be handled by database CASCADE rules
      // but we'll do soft delete for safety

      // First, deactivate all members
      await _client
          .from('household_members')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('household_id', householdId);

      // Then delete the household
      await _client.from('households').delete().eq('id', householdId);

      // Clear cache
      _membersCache.remove(householdId);
    } catch (e) {
      throw Exception('Failed to delete household: $e');
    }
  }

  // Get household by code (used for validation)
  Future<HouseholdModel?> getHouseholdByCode(String code) async {
    try {
      final trimmedCode = code.trim().toUpperCase();
      if (trimmedCode.length != 8) return null;

      // Use the secure RPC function to find the household
      final response =
          await _client
              .rpc(
                'find_household_by_code',
                params: {'search_code': trimmedCode},
              )
              .maybeSingle();

      if (response == null) return null;
      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch household by code: $e');
    }
  }

  // Cache management helpers
  bool _shouldUseCache(String householdId) {
    if (!_membersCache.containsKey(householdId)) return false;
    if (_lastCacheUpdate == null) return false;

    final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
    return cacheAge < _cacheExpiry;
  }

  void _clearCache() {
    _membersCache.clear();
    _lastCacheUpdate = null;
  }

  // Get member count for a household
  Future<int> getHouseholdMemberCount(String householdId) async {
    try {
      final response = await _client
          .from('household_members')
          .select('id')
          .eq('household_id', householdId)
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      throw Exception('Failed to get member count: $e');
    }
  }

  // Check if user is admin of a household
  Future<bool> isUserAdminOfHousehold(String householdId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response =
          await _client
              .from('household_members')
              .select('role')
              .eq('household_id', householdId)
              .eq('user_id', userId)
              .eq('is_active', true)
              .maybeSingle();

      return response?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}
