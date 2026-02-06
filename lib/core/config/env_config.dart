// lib/core/config/env_config.dart
// Centralized environment configuration with fallbacks for release builds

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Environment configuration with compile-time and runtime fallbacks.
/// 
/// Priority order:
/// 1. --dart-define values (compile-time, most secure for release)
/// 2. .env file values (runtime, for development)
/// 3. Hardcoded fallbacks (last resort)
/// 
/// For release builds, use:
/// flutter build apk --release \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
class EnvConfig {
  EnvConfig._();
  
  // ============================================================
  // IMPORTANT: Replace these with your actual Supabase credentials
  // These are public values (anon key is meant to be public)
  // ============================================================
  static const String _fallbackSupabaseUrl = 'https://pebdyufskmshvvshfqwj.supabase.co';
  static const String _fallbackSupabaseAnonKey = 'YOUR_ANON_KEY_HERE'; // TODO: Replace with actual anon key
  
  /// Whether the env file has been loaded
  static bool _envLoaded = false;
  
  /// Attempt to load .env file (safe to call multiple times)
  static Future<void> ensureLoaded() async {
    if (_envLoaded) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _envLoaded = true;
      if (kDebugMode) {
        debugPrint('✅ EnvConfig: .env file loaded');
      }
    } catch (e) {
      _envLoaded = true; // Mark as attempted
      if (kDebugMode) {
        debugPrint('⚠️ EnvConfig: .env not found, using fallbacks');
      }
    }
  }
  
  /// Get Supabase URL with fallback chain
  static String get supabaseUrl {
    // 1. Try dart-define (compile-time)
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;
    
    // 2. Try .env file (runtime)
    final envUrl = dotenv.env['SUPABASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    
    // 3. Fallback
    return _fallbackSupabaseUrl;
  }
  
  /// Get Supabase anon key with fallback chain
  static String get supabaseAnonKey {
    // 1. Try dart-define (compile-time)
    const dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    
    // 2. Try .env file (runtime)
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;
    
    // 3. Fallback
    return _fallbackSupabaseAnonKey;
  }
  
  /// Check if configuration is valid (not using placeholder values)
  static bool get isConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    
    return url.isNotEmpty && 
           key.isNotEmpty && 
           key != 'YOUR_ANON_KEY_HERE' &&
           url.contains('.supabase.co');
  }
  
  /// Debug: Print current configuration source
  static void debugPrintConfig() {
    if (!kDebugMode) return;
    
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final envUrl = dotenv.env['SUPABASE_URL'];
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    String urlSource = 'fallback';
    String keySource = 'fallback';
    
    if (dartDefineUrl.isNotEmpty) {
      urlSource = 'dart-define';
    } else if (envUrl != null && envUrl.isNotEmpty) {
      urlSource = '.env';
    }
    
    if (dartDefineKey.isNotEmpty) {
      keySource = 'dart-define';
    } else if (envKey != null && envKey.isNotEmpty) {
      keySource = '.env';
    }
    
    debugPrint('📋 EnvConfig:');
    debugPrint('   URL: ${supabaseUrl.substring(0, 30)}... (from $urlSource)');
    debugPrint('   Key: ${supabaseAnonKey.substring(0, 20)}... (from $keySource)');
    debugPrint('   Configured: $isConfigured');
  }
}
