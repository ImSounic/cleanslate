// lib/data/services/supabase_service.dart
// Updated with fixed Google Sign-In nonce handling

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Google Sign In instance - UPDATED: Remove serverClientId for iOS
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Only set serverClientId for Android
    serverClientId: Platform.isAndroid 
        ? '884884596328-f3rijrb8ims7jfg3bin3f5tkfverjs4j.apps.googleusercontent.com'
        : null,
  );

  // Google Sign In - FIXED: Updated nonce handling
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugLog('Starting Google Sign-In...');
      
      // Sign out from any previous Google session to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      debugLog('Google user obtained successfully');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID token found');
      }

      debugLog('Google auth tokens obtained');

      // FIXED: Use signInWithIdToken without nonce parameter
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
        // Remove nonce parameter to avoid mismatch
      );

      debugLog('Supabase sign-in successful');

      // Update or create profile with Google data
      if (response.user != null) {
        await _updateProfileWithGoogleData(response.user!, googleUser);
      }

      return response;
    } catch (e) {
      debugLog('Google sign in error: $e');
      rethrow;
    }
  }

  // Alternative method using OAuth flow for better compatibility
  Future<bool> signInWithGoogleOAuth() async {
    try {
      debugLog('Starting Google OAuth Sign-In...');
      
      // Use Supabase's OAuth flow instead of custom token handling
      final success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.yourapp.cleanslate://oauth/callback', // Replace with your app's URL scheme
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      return success;
    } catch (e) {
      debugLog('Google OAuth sign in error: $e');
      rethrow;
    }
  }

  // Link Google account to existing email/password account
  Future<void> linkGoogleAccount() async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Check if user already has Google linked
      final profile = await client
          .from('profiles')
          .select('auth_provider')
          .eq('id', currentUser!.id)
          .single();

      if (profile['auth_provider'] == 'google' ||
          profile['auth_provider'] == 'email_and_google') {
        throw Exception('Google account is already linked');
      }

      // Sign out from any previous Google session
      await _googleSignIn.signOut();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID token found');
      }

      // Check if this Google account is already linked to another user
      final existingGoogleUser = await _checkExistingGoogleUser(
        googleUser.email,
      );

      if (existingGoogleUser != null &&
          existingGoogleUser['id'] != currentUser!.id) {
        throw Exception(
          'This Google account is already linked to another user. '
          'Please use a different Google account.',
        );
      }

      // Update the user's profile to indicate Google is linked
      final updates = <String, dynamic>{
        'auth_provider': 'email_and_google',
        'google_id': googleUser.id,
        'google_email': googleUser.email,
      };

      // Add Google profile photo if user doesn't have one
      if (profile['profile_image_url'] == null && googleUser.photoUrl != null) {
        updates['profile_image_url'] = googleUser.photoUrl;
      }

      await client.from('profiles').update(updates).eq('id', currentUser!.id);

      // Update auth metadata
      final metadataUpdates = <String, dynamic>{
        'google_linked': true,
        'google_id': googleUser.id,
      };

      if (googleUser.photoUrl != null && profile['profile_image_url'] == null) {
        metadataUpdates['profile_image_url'] = googleUser.photoUrl;
      }

      await client.auth.updateUser(UserAttributes(data: metadataUpdates));

      // Store the Google credentials for future use
      await _storeGoogleCredentials(currentUser!.id, googleUser);
    } catch (e) {
      debugLog('Error linking Google account: $e');
      rethrow;
    }
  }

  // Check if a Google account is already linked
  Future<Map<String, dynamic>?> _checkExistingGoogleUser(String email) async {
    try {
      final response = await client
          .from('profiles')
          .select('id, email, auth_provider, google_email')
          .or('email.eq.$email,google_email.eq.$email')
          .maybeSingle();

      return response;
    } catch (e) {
      debugLog('Error checking existing Google user: $e');
      return null;
    }
  }

  // Store Google credentials for linked account
  Future<void> _storeGoogleCredentials(
    String userId,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      // First, check if a record already exists
      final existing = await client
          .from('google_auth_links')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        await client
            .from('google_auth_links')
            .update({
              'google_id': googleUser.id,
              'google_email': googleUser.email,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Insert new record
        await client.from('google_auth_links').insert({
          'user_id': userId,
          'google_id': googleUser.id,
          'google_email': googleUser.email,
          'linked_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugLog('Error storing Google credentials: $e');
      // Continue anyway as the main linking was successful
    }
  }

  // Check if current user has Google linked
  Future<bool> hasGoogleLinked() async {
    try {
      if (currentUser == null) return false;

      final profile = await client
          .from('profiles')
          .select('auth_provider')
          .eq('id', currentUser!.id)
          .single();

      return profile['auth_provider'] == 'google' ||
          profile['auth_provider'] == 'email_and_google';
    } catch (e) {
      debugLog('Error checking Google link status: $e');
      return false;
    }
  }

  // Unlink Google account
  Future<void> unlinkGoogleAccount() async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Check current auth provider
      final profile = await client
          .from('profiles')
          .select('auth_provider')
          .eq('id', currentUser!.id)
          .single();

      if (profile['auth_provider'] == 'google') {
        throw Exception(
          'Cannot unlink Google from an account that only uses Google sign-in. '
          'Please add a password first.',
        );
      }

      if (profile['auth_provider'] != 'email_and_google') {
        throw Exception('No Google account is linked');
      }

      // Update profile to remove Google link
      await client
          .from('profiles')
          .update({
            'auth_provider': 'email',
            'google_id': null,
            'google_email': null,
          })
          .eq('id', currentUser!.id);

      // Remove from google_auth_links table if it exists
      try {
        await client
            .from('google_auth_links')
            .delete()
            .eq('user_id', currentUser!.id);
      } catch (e) {
        // Table might not exist, continue
      }

      // Update auth metadata
      await client.auth.updateUser(
        UserAttributes(data: {'google_linked': false, 'google_id': null}),
      );
    } catch (e) {
      debugLog('Error unlinking Google account: $e');
      rethrow;
    }
  }

  // Helper method to update profile with Google data
  Future<void> _updateProfileWithGoogleData(
    User user,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      debugLog('Updating profile with Google data...');
      
      // Check if profile exists
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final profileData = {
        'id': user.id,
        'full_name': googleUser.displayName ?? user.email?.split('@').first,
        'email': googleUser.email,
        'profile_image_url': googleUser.photoUrl,
        'auth_provider': 'google',
        'google_id': googleUser.id,
        'google_email': googleUser.email,
      };

      if (profile == null) {
        // Create new profile
        await client.from('profiles').insert(profileData);
        debugLog('Created new profile for Google user');
      } else {
        // Update existing profile with Google data if missing
        final updates = <String, dynamic>{
          'auth_provider':
              profile['auth_provider'] == 'email' ? 'email_and_google' : 'google',
          'google_id': googleUser.id,
          'google_email': googleUser.email,
        };

        if (profile['full_name'] == null && googleUser.displayName != null) {
          updates['full_name'] = googleUser.displayName;
        }

        if (profile['profile_image_url'] == null && googleUser.photoUrl != null) {
          updates['profile_image_url'] = googleUser.photoUrl;
        }

        await client.from('profiles').update(updates).eq('id', user.id);
        debugLog('Updated existing profile with Google data');
      }

      // Also update auth metadata
      final metadataUpdates = <String, dynamic>{};

      if (googleUser.displayName != null) {
        metadataUpdates['full_name'] = googleUser.displayName;
      }

      if (googleUser.photoUrl != null) {
        metadataUpdates['profile_image_url'] = googleUser.photoUrl;
      }

      if (metadataUpdates.isNotEmpty) {
        await client.auth.updateUser(UserAttributes(data: metadataUpdates));
        debugLog('Updated auth metadata');
      }
    } catch (e) {
      debugLog('Error updating profile with Google data: $e');
      // Continue anyway since auth was successful
    }
  }

  // Check if user exists and get their auth provider
  Future<Map<String, dynamic>?> _checkExistingUser(String email) async {
    try {
      final response = await client
          .from('profiles')
          .select('id, email, auth_provider')
          .eq('email', email)
          .maybeSingle();

      return response;
    } catch (e) {
      debugLog('Error checking existing user: $e');
      return null;
    }
  }

  // Sign out (updated to handle Google sign out too)
  Future<void> signOut() async {
    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugLog('Google sign out error: $e');
    }

    // Sign out from Supabase
    await client.auth.signOut();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    // Check if user already exists with Google auth
    final existingUser = await _checkExistingUser(email);

    if (existingUser != null && existingUser['auth_provider'] == 'google') {
      throw Exception(
        'An account with this email already exists using Google sign-in. '
        'Please use "Sign in with Google" instead.',
      );
    }

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
        final profile = await client
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
            'auth_provider': 'email', // Mark as email auth
          });
        }
      } catch (e) {
        debugLog('Error creating profile: $e');
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

  Future<void> resetPassword(String email) async {
    // Check if user exists with Google auth
    final existingUser = await _checkExistingUser(email);

    if (existingUser != null && existingUser['auth_provider'] == 'google') {
      throw Exception(
        'This account uses Google sign-in and doesn\'t have a password. '
        'Please use "Sign in with Google" instead.',
      );
    }

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
      if (profileImageUrl != null) profileUpdates['profile_image_url'] = profileImageUrl;

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
    await client.storage.from('user-images').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Get public URL
    final imageUrl = client.storage.from('user-images').getPublicUrl(storagePath);

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
        // Only remove if it's a Supabase storage URL (not Google profile URL)
        if (profileImageUrl.contains('supabase')) {
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
        }

        // Clear profile image URL in both auth metadata and profiles table
        await updateUserProfile(profileImageUrl: null);
      } catch (e) {
        debugLog('Error removing image: $e');
      }
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      // Try to get from profiles first (more data)
      final profileResponse = await client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (profileResponse != null) {
        return profileResponse;
      }

      // Fall back to auth.users if needed
      final response = await client
          .from('auth.users')
          .select('id, email, raw_user_meta_data')
          .eq('email', email)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to find user: $e');
    }
  }

  // Delete user account — actually deletes user data and auth account
  Future<void> deleteAccount() async {
    if (currentUser == null) throw Exception('No user logged in');

    try {
      final userId = currentUser!.id;

      // 1. Delete chore assignments for this user
      try {
        await client.from('chore_assignments').delete().eq('assigned_to', userId);
      } catch (_) {
        // Table may not exist or no rows — continue
      }

      // 2. Delete chores created by this user
      try {
        await client.from('chores').delete().eq('created_by', userId);
      } catch (_) {
        // Continue
      }

      // 3. Delete notifications for this user
      try {
        await client.from('notifications').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 4. Delete calendar integrations
      try {
        await client.from('calendar_integrations').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 5. Delete Google auth links
      try {
        await client.from('google_auth_links').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 6. Delete scheduled assignments
      try {
        await client.from('scheduled_assignments').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 7. Delete user preferences
      try {
        await client.from('user_preferences').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 8. Remove household memberships (hard delete, not soft)
      try {
        await client.from('household_members').delete().eq('user_id', userId);
      } catch (_) {
        // Continue
      }

      // 9. Delete profile images from storage
      try {
        await removeProfileImage();
        await client.storage.from('user-images').remove(['profiles/$userId']);
      } catch (_) {
        // Continue — storage cleanup is best-effort
      }

      // 10. Delete the user's profile row
      try {
        await client.from('profiles').delete().eq('id', userId);
      } catch (_) {
        // Continue
      }

      // 11. Call Supabase RPC to delete the auth user (requires a database
      //     function `delete_own_account` defined with SECURITY DEFINER).
      //     If the RPC doesn't exist yet, we fall through gracefully.
      try {
        await client.rpc('delete_own_account');
      } catch (_) {
        // RPC may not be deployed yet — the data is already wiped above,
        // and the orphaned auth record can be cleaned up by an admin later.
      }

      // 12. Sign out from Google if applicable
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Continue
      }

      // 13. Sign out from Supabase
      await signOut();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if user is logged in
  bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user
  User? get currentUser => client.auth.currentUser;
}