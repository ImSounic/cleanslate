// lib/data/services/supabase_service.dart
// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Google Sign In instance
  // TODO: Add your Web Client ID from Google Cloud Console
  // This should be the Web Application OAuth 2.0 Client ID, not the Android one
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // For Android, use serverClientId instead of clientId
    serverClientId:
        '884884596328-f3rijrb8ims7jfg3bin3f5tkfverjs4j.apps.googleusercontent.com',
  );

  // Google Sign In
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Sign out from any previous Google session to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID token found');
      }

      // First, check if a user with this email already exists
      final email = googleUser.email;
      final existingUser = await _checkExistingUser(email);

      if (existingUser != null && existingUser['auth_provider'] != 'google') {
        // User exists with email/password auth
        throw Exception(
          'An account with this email already exists. Please sign in with your email and password, '
          'then link your Google account in settings.',
        );
      }

      // Sign in with Supabase using the Google ID token
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      // Update or create profile with Google data
      if (response.user != null) {
        try {
          // Check if profile exists
          final profile =
              await client
                  .from('profiles')
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          final profileData = {
            'id': response.user!.id,
            'full_name':
                googleUser.displayName ??
                response.user!.email?.split('@').first,
            'email': googleUser.email,
            'profile_image_url': googleUser.photoUrl,
            'auth_provider': 'google',
          };

          if (profile == null) {
            // Create new profile
            await client.from('profiles').insert(profileData);
          } else {
            // Update existing profile with Google data if missing
            final updates = <String, dynamic>{'auth_provider': 'google'};

            if (profile['full_name'] == null &&
                googleUser.displayName != null) {
              updates['full_name'] = googleUser.displayName;
            }

            if (profile['profile_image_url'] == null &&
                googleUser.photoUrl != null) {
              updates['profile_image_url'] = googleUser.photoUrl;
            }

            if (updates.isNotEmpty) {
              await client
                  .from('profiles')
                  .update(updates)
                  .eq('id', response.user!.id);
            }
          }

          // Also update auth metadata
          if (googleUser.displayName != null || googleUser.photoUrl != null) {
            final metadataUpdates = <String, dynamic>{};

            if (googleUser.displayName != null) {
              metadataUpdates['full_name'] = googleUser.displayName;
            }

            if (googleUser.photoUrl != null) {
              metadataUpdates['profile_image_url'] = googleUser.photoUrl;
            }

            await client.auth.updateUser(UserAttributes(data: metadataUpdates));
          }
        } catch (e) {
          print('Error updating profile with Google data: $e');
          // Continue anyway since auth was successful
        }
      }

      return response;
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  // Check if user exists and get their auth provider
  Future<Map<String, dynamic>?> _checkExistingUser(String email) async {
    try {
      final response =
          await client
              .from('profiles')
              .select('id, email, auth_provider')
              .eq('email', email)
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error checking existing user: $e');
      return null;
    }
  }

  // Link Google account to existing email/password account
  Future<void> linkGoogleAccount() async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Note: Supabase doesn't currently support linking identities from the client SDK
      // This would need to be implemented via a server-side function or Edge Function
      // For now, we'll throw an informative error
      throw Exception(
        'Account linking is not currently supported. '
        'Please contact support if you need to link your Google account.',
      );

      // When Supabase adds client-side identity linking, the implementation would be:
      /*
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

      // Link the identities (this would be the proper API when available)
      // await client.auth.linkIdentity(...);

      // Update profile with Google data if needed
      final updates = <String, dynamic>{
        'auth_provider': 'email_and_google', // Indicate both auth methods
      };
      
      if (googleUser.photoUrl != null) {
        updates['profile_image_url'] = googleUser.photoUrl;
      }
      
      await client
          .from('profiles')
          .update(updates)
          .eq('id', currentUser!.id);
          
      // Update auth metadata too
      if (googleUser.photoUrl != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'profile_image_url': googleUser.photoUrl})
        );
      }
      */
    } catch (e) {
      print('Error linking Google account: $e');
      rethrow;
    }
  }

  // Unlink Google account
  Future<void> unlinkGoogleAccount() async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Note: Supabase doesn't currently support unlinking identities from the client SDK
      // This would need to be implemented via a server-side function or Edge Function
      throw Exception(
        'Account unlinking is not currently supported. '
        'Please contact support if you need to unlink your Google account.',
      );

      // When Supabase adds client-side identity unlinking:
      /*
      // await client.auth.unlinkIdentity(...);
      
      // Update profile to indicate only email auth
      await client
          .from('profiles')
          .update({'auth_provider': 'email'})
          .eq('id', currentUser!.id);
      */
    } catch (e) {
      print('Error unlinking Google account: $e');
      rethrow;
    }
  }

  // Sign out (updated to handle Google sign out too)
  Future<void> signOut() async {
    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google sign out error: $e');
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
            'auth_provider': 'email', // Mark as email auth
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
    // Check if user exists with Google auth
    final existingUser = await _checkExistingUser(email);

    if (existingUser != null && existingUser['auth_provider'] == 'google') {
      throw Exception(
        'This account was created with Google sign-in. '
        'Please use "Sign in with Google" instead.',
      );
    }

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

      // Sign out from Google if applicable
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Google sign out error: $e');
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
