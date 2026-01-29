// lib/core/utils/error_handler.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

class ErrorHandler {
  // Handle errors and show appropriate messages
  static void handle(BuildContext context, dynamic error, {String? prefix}) {
    String message = _getErrorMessage(error);
    if (prefix != null) {
      message = '$prefix: $message';
    }

    showSnackBar(context, message, isError: true);
  }

  // Show success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  // Show snackbar with consistent styling
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred';

    // Handle Supabase exceptions
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    if (error is PostgrestException) {
      return _handleDatabaseError(error);
    }

    if (error is StorageException) {
      return _handleStorageError(error);
    }

    // Handle custom exceptions
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Exception: ')) {
        return message.split('Exception: ').last;
      }
    }

    // Network errors
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    // Default error message
    return error.toString().length > 100
        ? 'An error occurred. Please try again.'
        : error.toString();
  }

  // Handle authentication errors
  static String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        if (error.message.contains('email')) {
          return 'Invalid email address';
        }
        if (error.message.contains('password')) {
          return 'Invalid password';
        }
        return 'Invalid request. Please check your input.';

      case '422':
        return 'Invalid email or password format';

      case '401':
        return 'Invalid credentials. Please try again.';

      case '403':
        return 'Access denied. Please sign in again.';

      case '404':
        return 'Account not found';

      case '429':
        return 'Too many attempts. Please try again later.';

      default:
        return error.message;
    }
  }

  // Handle database errors
  static String _handleDatabaseError(PostgrestException error) {
    // Check for common constraint violations
    if (error.code == '23505') {
      if (error.message.contains('email')) {
        return 'This email is already registered';
      }
      if (error.message.contains('household')) {
        return 'A household with this name already exists';
      }
      return 'This item already exists';
    }

    if (error.code == '23503') {
      return 'Referenced item does not exist';
    }

    if (error.code == '23502') {
      return 'Required information is missing';
    }

    if (error.code == '42501') {
      return 'You do not have permission to perform this action';
    }

    // Default database error
    return 'Database error. Please try again.';
  }

  // Handle storage errors
  static String _handleStorageError(StorageException error) {
    if (error.statusCode == '413') {
      return 'File is too large. Please choose a smaller file.';
    }

    if (error.statusCode == '415') {
      return 'Invalid file type. Please choose a different file.';
    }

    if (error.statusCode == '404') {
      return 'File not found';
    }

    if (error.statusCode == '403') {
      return 'You do not have permission to access this file';
    }

    return 'Error uploading file. Please try again.';
  }

  // Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Switzer',
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'VarelaRound',
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style:
                  isDestructive
                      ? TextButton.styleFrom(foregroundColor: AppColors.error)
                      : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                        fontFamily: 'VarelaRound',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
}

// Error boundary widget
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return errorBuilder?.call(errorDetails) ??
          _defaultErrorWidget(context, errorDetails);
    };

    return child;
  }

  Widget _defaultErrorWidget(
    BuildContext context,
    FlutterErrorDetails errorDetails,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We apologize for the inconvenience. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to home or restart app
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
