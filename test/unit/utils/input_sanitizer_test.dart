// test/unit/utils/input_sanitizer_test.dart
// Unit tests for input sanitization utilities

import 'package:flutter_test/flutter_test.dart';
import 'package:cleanslate/core/utils/input_sanitizer.dart';

void main() {
  group('Input Sanitizer', () {
    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test household name sanitization
    // INTENDED USE: Prevent XSS and ensure clean household names in database
    // ══════════════════════════════════════════════════════════════════════════
    group('sanitizeHouseholdName', () {
      test('should trim whitespace from beginning and end', () {
        expect(sanitizeHouseholdName('  My Household  '), 'My Household');
        expect(sanitizeHouseholdName('\t\nTest\t\n'), 'Test');
      });

      test('should collapse multiple spaces into single space', () {
        expect(sanitizeHouseholdName('My    Household'), 'My Household');
        expect(sanitizeHouseholdName('The   Big   House'), 'The Big House');
      });

      test('should strip HTML tags', () {
        // The sanitizer strips <...> tags
        final result1 = sanitizeHouseholdName('House<script>alert()</script>');
        expect(result1.contains('<'), false);
        expect(result1.contains('>'), false);
        
        final result2 = sanitizeHouseholdName('<b>Bold</b>');
        expect(result2.contains('<'), false);
        expect(result2.contains('>'), false);
      });

      test('should handle normal household names unchanged', () {
        expect(sanitizeHouseholdName('Apartment 42'), 'Apartment 42');
        expect(sanitizeHouseholdName('The Smith Family'), 'The Smith Family');
        expect(sanitizeHouseholdName('123 Main St'), '123 Main St');
      });

      test('should handle empty input', () {
        expect(sanitizeHouseholdName(''), '');
        expect(sanitizeHouseholdName('   '), '');
      });

      test('should preserve valid special characters', () {
        expect(sanitizeHouseholdName("O'Brien's House"), "O'Brien's House");
        expect(sanitizeHouseholdName('Room #5'), 'Room #5');
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test chore name sanitization
    // INTENDED USE: Clean user input for chore names before database insertion
    // ══════════════════════════════════════════════════════════════════════════
    group('sanitizeChoreName', () {
      test('should trim whitespace', () {
        expect(sanitizeChoreName('  Clean Kitchen  '), 'Clean Kitchen');
      });

      test('should handle normal chore names', () {
        expect(sanitizeChoreName('Do Dishes'), 'Do Dishes');
        expect(sanitizeChoreName('Vacuum Living Room'), 'Vacuum Living Room');
        expect(sanitizeChoreName('Take out trash'), 'Take out trash');
      });

      test('should collapse multiple spaces', () {
        expect(sanitizeChoreName('Clean   the   bathroom'), 'Clean the bathroom');
      });

      test('should handle empty input', () {
        expect(sanitizeChoreName(''), '');
        expect(sanitizeChoreName('  '), '');
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test description sanitization
    // INTENDED USE: Clean chore descriptions while preserving line breaks
    // ══════════════════════════════════════════════════════════════════════════
    group('sanitizeDescription', () {
      test('should trim whitespace but preserve internal newlines', () {
        final input = '  First line\nSecond line  ';
        final result = sanitizeDescription(input);
        expect(result.contains('\n'), true);
      });

      test('should handle multiline descriptions', () {
        final input = 'Step 1: Do this\nStep 2: Do that\nStep 3: Done';
        final result = sanitizeDescription(input);
        expect(result.isNotEmpty, true);
      });

      test('should handle null or empty input', () {
        expect(sanitizeDescription(''), '');
        expect(sanitizeDescription('   '), '');
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test email validation pattern
    // INTENDED USE: Validate email format before authentication attempts
    // ══════════════════════════════════════════════════════════════════════════
    group('Email Validation Pattern', () {
      bool isValidEmail(String email) {
        return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
      }

      test('should accept valid email formats', () {
        expect(isValidEmail('test@example.com'), true);
        expect(isValidEmail('user.name@domain.org'), true);
        expect(isValidEmail('a@b.co'), true);
      });

      test('should reject invalid email formats', () {
        expect(isValidEmail('notanemail'), false);
        expect(isValidEmail('@nodomain.com'), false);
        expect(isValidEmail(''), false);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test household code validation pattern
    // INTENDED USE: Validate 8-character join codes before lookup
    // ══════════════════════════════════════════════════════════════════════════
    group('Household Code Validation Pattern', () {
      bool isValidHouseholdCode(String code) {
        return code.length == 8 && RegExp(r'^[A-Z0-9]+$').hasMatch(code);
      }

      test('should accept valid 8-character uppercase codes', () {
        expect(isValidHouseholdCode('ABC12345'), true);
        expect(isValidHouseholdCode('XXXXXXXX'), true);
        expect(isValidHouseholdCode('12345678'), true);
      });

      test('should reject codes with wrong length', () {
        expect(isValidHouseholdCode('ABC1234'), false); // 7 chars
        expect(isValidHouseholdCode('ABC123456'), false); // 9 chars
        expect(isValidHouseholdCode(''), false);
      });

      test('should reject lowercase codes', () {
        expect(isValidHouseholdCode('abcd1234'), false);
      });
    });
  });
}
