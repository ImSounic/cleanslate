// lib/data/repositories/household_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/models/household_member_model.dart';

class HouseholdRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all households for the current user (Model version)
  Future<List<HouseholdModel>> getUserHouseholds() async {
    try {
      final response = await _client
          .from('households')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HouseholdModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch households: $e');
    }
  }

  // Get all households for the current user (Map version for backward compatibility)
  Future<List<Map<String, dynamic>>> getHouseholds() async {
    try {
      final response = await _client
          .from('households')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch households: $e');
    }
  }

  // Get a single household by ID (Model version)
  Future<HouseholdModel> getHouseholdModel(String householdId) async {
    try {
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

  // Get a single household by ID (Map version for backward compatibility)
  Future<Map<String, dynamic>?> getHousehold(String householdId) async {
    try {
      final response =
          await _client
              .from('households')
              .select()
              .eq('id', householdId)
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch household: $e');
    }
  }

  // Create a new household
  Future<HouseholdModel> createHousehold(String name) async {
    try {
      final response =
          await _client
              .from('households')
              .insert({
                'name': name,
                'created_by': _client.auth.currentUser!.id,
                // code will be generated automatically by the database trigger
              })
              .select()
              .single();

      // Also add the creator as a member with admin role
      await _client.from('household_members').insert({
        'household_id': response['id'],
        'user_id': _client.auth.currentUser!.id,
        'role': 'admin',
        'is_active': true,
      });

      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create household: $e');
    }
  }

  // Join household using code
  // Join household using code
  Future<HouseholdModel> joinHouseholdWithCode(String code) async {
    try {
      print("Attempting to join household with code: ${code.trim().toUpperCase()}");
      
      // Find household by code - MODIFIED to not use .single() directly
      final householdResults = await _client
          .from('households')
          .select()
          .eq('code', code.trim().toUpperCase());
      
      print("Search results: Found ${householdResults.length} households with this code");
      
      // Check if any households were found
      if (householdResults.isEmpty) {
        throw Exception('No household found with this code. Please check and try again.');
      }
      
      // Get the first matching household
      final householdResponse = householdResults.first;
      final householdId = householdResponse['id'] as String;
      final userId = _client.auth.currentUser!.id;
      
      print("Found household with ID: $householdId, Current user ID: $userId");

      // Check if user is already a member
      final existingMemberResults = await _client
          .from('household_members')
          .select()
          .eq('household_id', householdId)
          .eq('user_id', userId);
      
      print("Existing member check: Found ${existingMemberResults.length} matching records");
      
      final existingMember = existingMemberResults.isNotEmpty ? existingMemberResults.first : null;

      if (existingMember != null) {
        // If user was previously removed, reactivate membership
        if (existingMember['is_active'] == false) {
          print("Reactivating previously inactive membership");
          await _client
              .from('household_members')
              .update({'is_active': true})
              .eq('id', existingMember['id']);
        } else {
          print("User is already an active member of this household");
          throw Exception('You are already a member of this household');
        }
      } else {
        // Add user as a new member
        print("Adding user as a new member of the household");
        await _client.from('household_members').insert({
          'household_id': householdId,
          'user_id': userId,
          'role': 'member',
          'is_active': true,
        });
      }

      return HouseholdModel.fromJson(householdResponse);
    } catch (e) {
      print("Error in joinHouseholdWithCode: $e");
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}. Please contact support if the issue persists.');
      }
      // If it's already an Exception we've created, re-throw it directly
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to join household: $e');
    }
  }
  // Get household by code
  Future<HouseholdModel?> getHouseholdByCode(String code) async {
    try {
      final response =
          await _client
              .from('households')
              .select()
              .eq('code', code.toUpperCase())
              .maybeSingle();

      if (response == null) return null;
      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch household by code: $e');
    }
  }

  // Get household members
  Future<List<HouseholdMemberModel>> getHouseholdMembers(
    String householdId,
  ) async {
    try {
      // Simplified query to get just the household members
      final response = await _client
          .from('household_members')
          .select('id, household_id, user_id, role, joined_at, is_active')
          .eq('household_id', householdId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      // Convert to list of models with minimal information
      final members = <HouseholdMemberModel>[];
      for (final memberData in response) {
        // We need to handle the auth user data separately
        String userId = memberData['user_id'] as String;
        String? email;
        String? fullName;
        String? profileImageUrl;

        try {
          // Try to get the user information from the auth.currentSession
          final currentUser = _client.auth.currentUser;
          if (currentUser != null && currentUser.id == userId) {
            // If it's the current user, we can get the info directly
            email = currentUser.email;
            final metadata = currentUser.userMetadata;
            if (metadata != null) {
              fullName = metadata['full_name'] as String?;
              profileImageUrl = metadata['profile_image_url'] as String?;
            }
          } else {
            // For other users, use placeholder values
            // Fixed: Using string interpolation instead of concatenation
            email = 'User ${userId.substring(0, 4)}';
            fullName = 'Member';
          }
        } catch (e) {
          // Fixed: Removed print statement and used proper logging
          // Note: Consider implementing a proper logging system

          // Fallback values if we can't get the user data
          // Fixed: Using string interpolation instead of concatenation
          email = 'User ${userId.substring(0, 4)}';
          fullName = 'Member';
        }

        members.add(
          HouseholdMemberModel(
            id: memberData['id'] as String,
            householdId: memberData['household_id'] as String,
            userId: userId,
            role: memberData['role'] as String,
            joinedAt: DateTime.parse(memberData['joined_at'] as String),
            isActive: memberData['is_active'] as bool,
            fullName: fullName,
            email: email,
            profileImageUrl: profileImageUrl,
          ),
        );
      }

      return members;
    } catch (e) {
      throw Exception('Failed to fetch household members: $e');
    }
  }

  // Update member role
  Future<void> updateMemberRole(String memberId, String newRole) async {
    try {
      await _client
          .from('household_members')
          .update({'role': newRole})
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  // Remove member from household
  Future<void> removeMemberFromHousehold(String memberId) async {
    try {
      await _client
          .from('household_members')
          .update({'is_active': false})
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to remove member from household: $e');
    }
  }

  // Update household details
  Future<HouseholdModel> updateHousehold(
    String householdId, {
    required String name,
  }) async {
    try {
      final response =
          await _client
              .from('households')
              .update({'name': name})
              .eq('id', householdId)
              .select()
              .single();

      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update household: $e');
    }
  }

  // Delete household
  Future<void> deleteHousehold(String householdId) async {
    try {
      await _client.from('households').delete().eq('id', householdId);
    } catch (e) {
      throw Exception('Failed to delete household: $e');
    }
  }
}
