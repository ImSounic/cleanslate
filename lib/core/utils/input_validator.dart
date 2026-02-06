// lib/core/utils/input_validator.dart
// Client-side input validation for form fields.
// Use with TextFormField.validator for immediate user feedback.
// Note: Server-side DB constraints are the authoritative validation layer.

import 'package:cleanslate/core/utils/input_sanitizer.dart';

/// Provides validation methods for all user input fields.
///
/// **Usage:**
/// ```dart
/// TextFormField(
///   validator: InputValidator.validateChoreTitle,
/// )
/// ```
///
/// **Security Note:** These validations provide user feedback.
/// The database CHECK constraints (add_column_constraints.sql) are
/// the authoritative server-side validation.
class InputValidator {
  // ═══════════════════════════════════════════════════════════════
  // CHORE FIELDS
  // ═══════════════════════════════════════════════════════════════

  /// Validates a chore title/name.
  /// - Required, 1-200 characters
  static String? validateChoreTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title for the chore';
    }
    final trimmed = value.trim();
    if (trimmed.length > 200) {
      return 'Title must be 200 characters or less';
    }
    if (_containsPotentialXSS(trimmed)) {
      return 'Title contains invalid characters';
    }
    return null;
  }

  /// Validates a chore description.
  /// - Optional, max 2000 characters
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.length > 2000) {
      return 'Description must be 2000 characters or less';
    }
    if (_containsPotentialXSS(value)) {
      return 'Description contains invalid characters';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // HOUSEHOLD FIELDS
  // ═══════════════════════════════════════════════════════════════

  /// Validates a household name.
  /// - Required, 1-100 characters
  static String? validateHouseholdName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a household name';
    }
    final trimmed = value.trim();
    if (trimmed.length > 100) {
      return 'Household name must be 100 characters or less';
    }
    if (_containsPotentialXSS(trimmed)) {
      return 'Household name contains invalid characters';
    }
    return null;
  }

  /// Validates a household invite code.
  /// - Required, exactly 8 alphanumeric characters
  static String? validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a household code';
    }
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length != 8) {
      return 'Code must be exactly 8 characters';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmed)) {
      return 'Code must contain only letters and numbers';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE FIELDS
  // ═══════════════════════════════════════════════════════════════

  /// Validates a display name.
  /// - Required, 1-100 characters
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    final trimmed = value.trim();
    if (trimmed.length > 100) {
      return 'Name must be 100 characters or less';
    }
    if (_containsPotentialXSS(trimmed)) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  /// Validates a display name (optional version).
  /// - Optional, max 100 characters
  static String? validateDisplayNameOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    return validateDisplayName(value);
  }

  /// Validates a bio.
  /// - Optional, max 500 characters
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.length > 500) {
      return 'Bio must be 500 characters or less';
    }
    if (_containsPotentialXSS(value)) {
      return 'Bio contains invalid characters';
    }
    return null;
  }

  /// Validates a phone number.
  /// - Optional, max 20 characters, digits/spaces/+/-/() only
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim();
    if (trimmed.length > 20) {
      return 'Phone number is too long';
    }
    if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTH FIELDS
  // ═══════════════════════════════════════════════════════════════

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final trimmed = value.trim().toLowerCase();
    // Basic email regex - not exhaustive but catches common issues
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    if (trimmed.length > 254) {
      return 'Email address is too long';
    }
    return null;
  }

  /// Validates a password.
  /// - Minimum 8 characters
  /// - At least one letter and one number recommended
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password is too long';
    }
    // Check for at least one letter and one number
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates a password confirmation matches.
  static String? Function(String?) validatePasswordConfirmation(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION FIELDS
  // ═══════════════════════════════════════════════════════════════

  /// Validates a notification title.
  /// - Optional, max 200 characters
  static String? validateNotificationTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.length > 200) {
      return 'Title must be 200 characters or less';
    }
    return null;
  }

  /// Validates a notification message.
  /// - Optional, max 2000 characters
  static String? validateNotificationMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.length > 2000) {
      return 'Message must be 2000 characters or less';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // UUID VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Validates that a value is a valid UUID format.
  static String? validateUUID(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invalid identifier';
    }
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(value.trim())) {
      return 'Invalid identifier format';
    }
    return null;
  }

  /// Returns true if the value is a valid UUID.
  static bool isValidUUID(String? value) {
    return validateUUID(value) == null;
  }

  // ═══════════════════════════════════════════════════════════════
  // SANITIZATION WRAPPERS
  // ═══════════════════════════════════════════════════════════════

  /// Sanitizes input and validates in one step.
  /// Returns the sanitized value if valid, or throws if invalid.
  static String sanitizeAndValidate({
    required String input,
    required String? Function(String?) validator,
    required int maxLength,
    bool multiLine = false,
  }) {
    final sanitized = multiLine
        ? sanitizeInput(input, maxLength: maxLength)
        : sanitizeSingleLine(input, maxLength: maxLength);
    
    final error = validator(sanitized);
    if (error != null) {
      throw ValidationException(error);
    }
    
    return sanitized;
  }

  // ═══════════════════════════════════════════════════════════════
  // XSS DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Checks if a string contains potential XSS attack patterns.
  /// This is a defense-in-depth measure - Flutter Text widgets
  /// don't execute scripts, but we still want to reject suspicious input.
  static bool _containsPotentialXSS(String input) {
    // Common XSS patterns
    final patterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick=, onerror=, etc.
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Public method to check for XSS (for use in custom validators).
  static bool containsPotentialXSS(String input) => _containsPotentialXSS(input);
}

/// Exception thrown when validation fails.
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
