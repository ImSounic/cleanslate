// lib/core/utils/secure_storage_helper.dart
// Secure storage wrapper for sensitive data.
// Uses flutter_secure_storage for encrypted storage on device.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

/// Provides secure storage for sensitive data like tokens.
///
/// **Security Notes:**
/// - Uses platform-specific encryption (Keychain on iOS, EncryptedSharedPreferences on Android)
/// - NEVER store passwords in plain text - auth is handled by Supabase
/// - Clear all secure data on logout
/// - Do not log any values from secure storage
class SecureStorageHelper {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Use StrongBox if available for hardware-backed security
      // sharedPreferencesName: 'cleanslate_secure_prefs',
      // preferencesKeyPrefix: 'cleanslate_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // accountName: 'com.imsounic.cleanslate',
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  // KEY CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  // Note: Supabase handles auth tokens internally via its own secure storage.
  // These keys are for any additional sensitive data the app needs to store.

  static const _keyRefreshToken = 'cleanslate_refresh_token';
  static const _keyCalendarAccessToken = 'cleanslate_calendar_token';
  static const _keyCalendarRefreshToken = 'cleanslate_calendar_refresh';
  static const _keyUserPreferencesEncrypted = 'cleanslate_prefs_encrypted';

  // ═══════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Stores a refresh token securely.
  /// Note: Supabase typically handles this internally.
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
      debugLog('SecureStorage: Refresh token saved');
    } catch (e) {
      debugLog('SecureStorage: Failed to save refresh token');
      // Don't rethrow - failing to save shouldn't crash the app
    }
  }

  /// Retrieves the stored refresh token.
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugLog('SecureStorage: Failed to read refresh token');
      return null;
    }
  }

  /// Deletes the stored refresh token.
  static Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _keyRefreshToken);
      debugLog('SecureStorage: Refresh token deleted');
    } catch (e) {
      debugLog('SecureStorage: Failed to delete refresh token');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CALENDAR TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Stores calendar access token securely.
  static Future<void> saveCalendarAccessToken(String token) async {
    try {
      await _storage.write(key: _keyCalendarAccessToken, value: token);
      debugLog('SecureStorage: Calendar access token saved');
    } catch (e) {
      debugLog('SecureStorage: Failed to save calendar token');
    }
  }

  /// Retrieves the stored calendar access token.
  static Future<String?> getCalendarAccessToken() async {
    try {
      return await _storage.read(key: _keyCalendarAccessToken);
    } catch (e) {
      debugLog('SecureStorage: Failed to read calendar token');
      return null;
    }
  }

  /// Stores calendar refresh token securely.
  static Future<void> saveCalendarRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyCalendarRefreshToken, value: token);
      debugLog('SecureStorage: Calendar refresh token saved');
    } catch (e) {
      debugLog('SecureStorage: Failed to save calendar refresh token');
    }
  }

  /// Retrieves the stored calendar refresh token.
  static Future<String?> getCalendarRefreshToken() async {
    try {
      return await _storage.read(key: _keyCalendarRefreshToken);
    } catch (e) {
      debugLog('SecureStorage: Failed to read calendar refresh token');
      return null;
    }
  }

  /// Deletes all calendar tokens.
  static Future<void> deleteCalendarTokens() async {
    try {
      await _storage.delete(key: _keyCalendarAccessToken);
      await _storage.delete(key: _keyCalendarRefreshToken);
      debugLog('SecureStorage: Calendar tokens deleted');
    } catch (e) {
      debugLog('SecureStorage: Failed to delete calendar tokens');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERIC SECURE KEY-VALUE STORAGE
  // ═══════════════════════════════════════════════════════════════

  /// Writes a value to secure storage.
  /// Use for any sensitive data that shouldn't be in SharedPreferences.
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugLog('SecureStorage: Failed to write key $key');
    }
  }

  /// Reads a value from secure storage.
  static Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugLog('SecureStorage: Failed to read key $key');
      return null;
    }
  }

  /// Deletes a value from secure storage.
  static Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugLog('SecureStorage: Failed to delete key $key');
    }
  }

  /// Checks if a key exists in secure storage.
  static Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGOUT / CLEAR ALL
  // ═══════════════════════════════════════════════════════════════

  /// Clears ALL data from secure storage.
  /// **MUST be called on logout** to ensure no sensitive data remains.
  static Future<void> clearAllOnLogout() async {
    try {
      await _storage.deleteAll();
      debugLog('SecureStorage: All secure data cleared on logout');
    } catch (e) {
      debugLog('SecureStorage: Failed to clear all data on logout');
      // Try to delete known keys individually as fallback
      await _clearKnownKeys();
    }
  }

  /// Fallback method to clear known keys if deleteAll fails.
  static Future<void> _clearKnownKeys() async {
    final knownKeys = [
      _keyRefreshToken,
      _keyCalendarAccessToken,
      _keyCalendarRefreshToken,
      _keyUserPreferencesEncrypted,
    ];

    for (final key in knownKeys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Continue with other keys
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SECURITY AUDIT HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Returns all keys in secure storage (for debugging only).
  /// **Do not call in production or log the values!**
  static Future<Set<String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      return all.keys.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Checks if secure storage is available and working.
  static Future<bool> isAvailable() async {
    try {
      const testKey = '__cleanslate_test_key__';
      const testValue = 'test';
      
      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      return readValue == testValue;
    } catch (e) {
      debugLog('SecureStorage: Storage availability check failed');
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SECURITY GUIDELINES FOR DEVELOPERS
// ═══════════════════════════════════════════════════════════════
//
// 1. WHAT TO STORE IN SECURE STORAGE:
//    - OAuth tokens (calendar, third-party services)
//    - API keys that aren't in the app bundle
//    - Encryption keys for local data
//
// 2. WHAT NOT TO STORE:
//    - Passwords (auth is handled by Supabase)
//    - Supabase tokens (Supabase SDK handles these)
//    - Large data (secure storage is for small values)
//
// 3. WHAT TO USE SharedPreferences FOR:
//    - User preferences (theme, notifications, etc.)
//    - Onboarding completion flags
//    - Non-sensitive cached data
//
// 4. NEVER:
//    - Log values from secure storage
//    - Store secure values in state management
//    - Transmit secure values except to the intended API
//
// ═══════════════════════════════════════════════════════════════
