// lib/core/services/deep_link_service.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

/// Service to handle deep links for CleanSlate app
/// 
/// Supported links:
/// - cleanslate://join/{code} - Join household with invite code
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  
  /// Callback for when a join code is received
  void Function(String code)? onJoinCodeReceived;
  
  /// Pending join code (received before callback was set)
  String? _pendingJoinCode;
  
  /// Get and clear pending join code
  String? consumePendingJoinCode() {
    final code = _pendingJoinCode;
    _pendingJoinCode = null;
    return code;
  }

  /// Initialize the deep link service
  Future<void> initialize() async {
    _appLinks = AppLinks();
    
    // Handle initial link (app opened via deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugLog('🔗 DeepLink: Initial link received: $initialUri');
        _handleUri(initialUri);
      }
    } catch (e) {
      debugLog('🔗 DeepLink: Error getting initial link: $e');
    }
    
    // Handle links while app is running
    _subscription = _appLinks.uriLinkStream.listen((Uri uri) {
      debugLog('🔗 DeepLink: Link received: $uri');
      _handleUri(uri);
    }, onError: (e) {
      debugLog('🔗 DeepLink: Stream error: $e');
    });
  }
  
  /// Parse and handle a deep link URI
  void _handleUri(Uri uri) {
    debugLog('🔗 DeepLink: Handling URI: $uri');
    debugLog('🔗 DeepLink: Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    
    // Handle cleanslate://join/{code}
    if (uri.scheme == 'cleanslate' && uri.host == 'join') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final code = pathSegments.first.toUpperCase();
        debugLog('🔗 DeepLink: Join code extracted: $code');
        _handleJoinCode(code);
      }
    }
    // Also handle https://cleanslate.app/join/{code} for web links
    else if ((uri.scheme == 'https' || uri.scheme == 'http') && 
             uri.host == 'cleanslate.app' &&
             uri.pathSegments.isNotEmpty &&
             uri.pathSegments.first == 'join' &&
             uri.pathSegments.length > 1) {
      final code = uri.pathSegments[1].toUpperCase();
      debugLog('🔗 DeepLink: Join code extracted from web link: $code');
      _handleJoinCode(code);
    }
  }
  
  /// Handle a join code
  void _handleJoinCode(String code) {
    // Validate code format (8 alphanumeric characters)
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
      debugLog('🔗 DeepLink: Invalid code format: $code');
      return;
    }
    
    if (onJoinCodeReceived != null) {
      onJoinCodeReceived!(code);
    } else {
      // Store for later if callback not set yet
      _pendingJoinCode = code;
      debugLog('🔗 DeepLink: Stored pending join code: $code');
    }
  }
  
  /// Parse a join code from a string (could be raw code or deep link)
  static String? parseJoinCode(String input) {
    final trimmed = input.trim();
    
    // Try to parse as URI first
    try {
      final uri = Uri.parse(trimmed);
      
      // Handle cleanslate://join/{code}
      if (uri.scheme == 'cleanslate' && uri.host == 'join') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final code = pathSegments.first.toUpperCase();
          if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
            return code;
          }
        }
      }
      // Handle https://cleanslate.app/join/{code}
      else if (uri.scheme == 'https' && 
               uri.host == 'cleanslate.app' &&
               uri.pathSegments.length > 1 &&
               uri.pathSegments.first == 'join') {
        final code = uri.pathSegments[1].toUpperCase();
        if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
          return code;
        }
      }
    } catch (_) {
      // Not a valid URI, continue
    }
    
    // Try as raw code
    final code = trimmed.toUpperCase();
    if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
      return code;
    }
    
    return null;
  }
  
  /// Dispose of the service
  void dispose() {
    _subscription?.cancel();
  }
}
