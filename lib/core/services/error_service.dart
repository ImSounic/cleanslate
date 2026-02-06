// lib/core/services/error_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorService {
  static const Map<String, ErrorInfo> _errorMap = {
    // Auth errors (E1xx)
    'AuthException': ErrorInfo('E101', 'Authentication failed. Please sign in again.'),
    'AuthApiException': ErrorInfo('E102', 'Login failed. Check your credentials.'),
    'AuthRetryableFetchError': ErrorInfo('E103', 'Connection issue. Please try again.'),
    'AuthSessionMissingException': ErrorInfo('E104', 'Session expired. Please sign in again.'),

    // Database errors (E2xx)
    'PostgrestException': ErrorInfo('E201', 'Database error. Please try again.'),

    // Network errors (E3xx)
    'SocketException': ErrorInfo('E301', 'No internet connection. Check your network.'),
    'TimeoutException': ErrorInfo('E302', 'Request timed out. Please try again.'),
    'ClientException': ErrorInfo('E303', 'Connection failed. Please try again.'),

    // Validation errors (E4xx)
    'FormatException': ErrorInfo('E401', 'Invalid data format.'),

    // Permission errors (E5xx)
    'StorageException': ErrorInfo('E501', 'Unable to access storage.'),
    'PlatformException': ErrorInfo('E502', 'Device feature unavailable.'),
  };

  /// Log error for developers, return friendly message for users.
  static String handleError(dynamic error, {String? operation}) {
    debugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugLog('❌ ERROR${operation != null ? " [$operation]" : ""}');
    debugLog('Type: ${error.runtimeType}');
    debugLog('Message: $error');
    if (error is PostgrestException) {
      debugLog('Code: ${error.code}');
      debugLog('Details: ${error.details}');
      debugLog('Hint: ${error.hint}');
    }
    debugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Log to Crashlytics (non-fatal)
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: operation,
      fatal: false,
    );

    final errorType = error.runtimeType.toString();
    final info = _errorMap[errorType];

    if (info != null) {
      return '${info.message} (${info.code})';
    }

    // Check for common string patterns in the error message
    final msg = error.toString().toLowerCase();
    if (msg.contains('internet') || msg.contains('network') || msg.contains('connection')) {
      return 'No internet connection. Check your network. (E301)';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again. (E302)';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. (E503)';
    }

    return 'Something went wrong. Please try again. (E000)';
  }

  /// Show error snackbar with a copy-code action.
  static void showError(BuildContext context, dynamic error, {String? operation}) {
    final message = handleError(error, operation: operation);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Copy',
          textColor: AppColors.textLight,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Error code copied'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Async-safe variant — accepts a pre-captured [ScaffoldMessengerState].
  static void showErrorSafe(
    ScaffoldMessengerState messenger,
    dynamic error, {
    String? operation,
  }) {
    final message = handleError(error, operation: operation);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

class ErrorInfo {
  final String code;
  final String message;
  const ErrorInfo(this.code, this.message);
}
