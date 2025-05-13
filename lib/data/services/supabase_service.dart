// lib/data/services/supabase_service.dart
// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );

    // The trigger will automatically create a profile,
    // but we can explicitly ensure it exists here for safety
    if (response.user != null) {
      try {
        // Check if profile exists
        final profile =
            await client
                .from('profiles')
                .select()
                .eq('id', response.user!.id)
                .maybeSingle();

        // If profile doesn't exist, create it
        if (profile == null) {
          await client.from('profiles').insert({
            'id': response.user!.id,
            'full_name': userData?['full_name'],
            'email': email,
          });
        }
      } catch (e) {
        print('Error creating profile: $e');
        // Continue anyway since the trigger should handle this
      }
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update user profile - now updates both auth metadata and profiles table
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (currentUser == null) throw Exception('No user logged in');

    // Auth metadata updates
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

    if (updates.isNotEmpty) {
      // Update auth user metadata
      await client.auth.updateUser(UserAttributes(data: updates));

      // Also update public profile
      final profileUpdates = <String, dynamic>{};
      if (fullName != null) profileUpdates['full_name'] = fullName;
      if (profileImageUrl != null)
        profileUpdates['profile_image_url'] = profileImageUrl;

      if (profileUpdates.isNotEmpty) {
        await client
            .from('profiles')
            .update(profileUpdates)
            .eq('id', currentUser!.id);
      }
    }
  }

  // Upload profile image to storage
  Future<String> uploadProfileImage(String filePath) async {
    if (currentUser == null) throw Exception('No user logged in');

    final userId = currentUser!.id;
    final file = File(filePath);
    final fileName = '${const Uuid().v4()}${path.extension(filePath)}';
    final storagePath = 'profiles/$userId/$fileName';

    // If there's an existing image, remove it first
    await removeProfileImage();

    // Upload to storage
    await client.storage
        .from('user-images')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Get public URL
    final imageUrl = client.storage
        .from('user-images')
        .getPublicUrl(storagePath);

    // Update profile with new URL
    await updateUserProfile(profileImageUrl: imageUrl);

    return imageUrl;
  }

  // Remove profile image
  Future<void> removeProfileImage() async {
    if (currentUser == null) throw Exception('No user logged in');

    final userData = currentUser!.userMetadata;
    final profileImageUrl = userData?['profile_image_url'] as String?;

    if (profileImageUrl != null) {
      try {
        // Find all files in the user's profile folder
        final userId = currentUser!.id;
        final List<FileObject> files = await client.storage
            .from('user-images')
            .list(path: 'profiles/$userId');

        // Delete each file
        if (files.isNotEmpty) {
          final filesToDelete =
              files.map((file) => 'profiles/$userId/${file.name}').toList();
          await client.storage.from('user-images').remove(filesToDelete);
        }

        // Clear profile image URL in both auth metadata and profiles table
        await updateUserProfile(profileImageUrl: null);
      } catch (e) {
        print('Error removing image: $e');
      }
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      // Try to get from profiles first (more data)
      final profileResponse =
          await client
              .from('profiles')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (profileResponse != null) {
        return profileResponse;
      }

      // Fall back to auth.users if needed
      final response =
          await client
              .from('auth.users')
              .select('id, email, raw_user_meta_data')
              .eq('email', email)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to find user: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    if (currentUser == null) throw Exception('No user logged in');

    try {
      final userId = currentUser!.id;

      // Remove from any households (set is_active to false)
      await client
          .from('household_members')
          .update({'is_active': false})
          .eq('user_id', userId);

      // Delete profile images
      await removeProfileImage();

      // Delete the user's profile folder
      try {
        await client.storage.from('user-images').remove(['profiles/$userId']);
      } catch (e) {
        print('Error removing folder: $e');
      }

      // Sign out the user
      await signOut();

      // Note: For actual account deletion, you would need to implement
      // a Supabase Edge Function or use admin API since client-side
      // deletion is not supported directly.
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if user is logged in
  bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user
  User? get currentUser => client.auth.currentUser;
}
