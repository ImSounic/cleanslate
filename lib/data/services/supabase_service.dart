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
    return await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
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

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (currentUser == null) throw Exception('No user logged in');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

    await client.auth.updateUser(UserAttributes(data: updates));
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
      } catch (e) {
        print('Error removing image: $e');
      }
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
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

  // Send OTP to email or phone
  Future<void> sendOtp({
    required String contactInfo,
    required bool isEmail,
  }) async {
    try {
      if (isEmail) {
        // Send email OTP
        await client.auth.signInWithOtp(email: contactInfo);
      } else {
        // Send phone OTP
        await client.auth.signInWithOtp(phone: contactInfo);
      }
    } catch (e) {
      throw Exception('Failed to send verification code: $e');
    }
  }

  // Verify OTP
  // Add these methods to lib/data/services/supabase_service.dart
  // These should be added within the SupabaseService class

  // Send OTP to email
  Future<void> sendEmailOtp({required String email}) async {
    try {
      await client.auth.signInWithOtp(email: email);
    } catch (e) {
      throw Exception('Failed to send verification code: $e');
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final AuthResponse response = await client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      );

      return response.session != null;
    } catch (e) {
      throw Exception('Failed to verify code: $e');
    }
  }

  // Check if user is logged in
  bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user
  User? get currentUser => client.auth.currentUser;
}
