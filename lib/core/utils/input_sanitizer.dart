// lib/core/utils/input_sanitizer.dart
// Input sanitization utilities for user-generated content before DB writes.

/// Sanitizes a user-provided string for safe storage.
///
/// - Trims leading/trailing whitespace
/// - Collapses multiple spaces into one
/// - Strips HTML tags to prevent XSS
/// - Removes null bytes and control characters (except newline/tab)
/// - Optionally enforces a max length
String sanitizeInput(String input, {int? maxLength}) {
  // Trim whitespace
  String sanitized = input.trim();

  // Remove null bytes and control characters (keep \n and \t)
  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

  // Strip HTML tags
  sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

  // Collapse multiple whitespace (but preserve single newlines)
  sanitized = sanitized.replaceAll(RegExp(r'[^\S\n]+'), ' ');

  // Enforce max length if specified
  if (maxLength != null && sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }

  return sanitized;
}

/// Sanitizes a single-line input (e.g., names, titles).
/// Removes all newlines in addition to standard sanitization.
String sanitizeSingleLine(String input, {int? maxLength}) {
  String sanitized = sanitizeInput(input, maxLength: maxLength);
  // Remove newlines for single-line fields
  sanitized = sanitized.replaceAll(RegExp(r'\n+'), ' ').trim();
  return sanitized;
}

/// Validates and sanitizes a household name.
/// Max 100 characters, single-line.
String sanitizeHouseholdName(String input) {
  return sanitizeSingleLine(input, maxLength: 100);
}

/// Validates and sanitizes a chore name/title.
/// Max 200 characters, single-line.
String sanitizeChoreName(String input) {
  return sanitizeSingleLine(input, maxLength: 200);
}

/// Validates and sanitizes a description (multi-line allowed).
/// Max 2000 characters.
String sanitizeDescription(String input) {
  return sanitizeInput(input, maxLength: 2000);
}

/// Validates and sanitizes a profile name.
/// Max 100 characters, single-line.
String sanitizeProfileName(String input) {
  return sanitizeSingleLine(input, maxLength: 100);
}

/// Validates and sanitizes a bio (multi-line allowed).
/// Max 500 characters.
String sanitizeBio(String input) {
  return sanitizeInput(input, maxLength: 500);
}

/// Validates and sanitizes a phone number.
/// Only allows digits, +, -, spaces, and parentheses.
String sanitizePhoneNumber(String input) {
  String sanitized = input.trim();
  sanitized = sanitized.replaceAll(RegExp(r'[^\d\s\+\-\(\)]'), '');
  if (sanitized.length > 20) {
    sanitized = sanitized.substring(0, 20);
  }
  return sanitized;
}
