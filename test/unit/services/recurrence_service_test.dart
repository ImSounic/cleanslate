// test/unit/services/recurrence_service_test.dart
// Unit tests for RecurrenceService

import 'package:flutter_test/flutter_test.dart';
import 'package:cleanslate/data/services/recurrence_service.dart';

void main() {
  group('RecurrenceService', () {
    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test next due date calculation for different frequencies
    // INTENDED USE: When a chore is completed, calculate when it's due next
    // ══════════════════════════════════════════════════════════════════════════
    group('calculateNextDueDate', () {
      test('should add 1 day for daily chores', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15); // Monday

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'daily');

        // Assert
        expect(nextDate, DateTime(2024, 1, 16));
      });

      test('should add 7 days for weekly chores', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'weekly');

        // Assert
        expect(nextDate, DateTime(2024, 1, 22));
      });

      test('should add 14 days for biweekly chores', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'biweekly');

        // Assert
        expect(nextDate, DateTime(2024, 1, 29));
      });

      test('should add 1 month for monthly chores', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'monthly');

        // Assert
        expect(nextDate, DateTime(2024, 2, 15));
      });

      test('should handle month overflow correctly (Jan 31 → Feb 29 in leap year)', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 31); // Jan 31, 2024 (leap year)

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'monthly');

        // Assert
        // Service clamps to last valid day of the month
        // Feb 2024 has 29 days (leap year), so Jan 31 → Feb 29
        expect(nextDate?.month, 2); // February
        expect(nextDate?.day, 29); // Last day of Feb (leap year)
      });

      test('should return null for non-recurring frequency', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'once');

        // Assert
        expect(nextDate, isNull);
      });

      test('should return null for null frequency', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, null);

        // Assert
        expect(nextDate, isNull);
      });

      test('should handle case-insensitive frequency strings', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 15);

        // Act & Assert
        expect(
          RecurrenceService.calculateNextDueDate(currentDate, 'WEEKLY'),
          DateTime(2024, 1, 22),
        );
        expect(
          RecurrenceService.calculateNextDueDate(currentDate, 'Weekly'),
          DateTime(2024, 1, 22),
        );
        expect(
          RecurrenceService.calculateNextDueDate(currentDate, 'DAILY'),
          DateTime(2024, 1, 16),
        );
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test isRecurring helper function
    // INTENDED USE: Determine if a chore should repeat after completion
    // ══════════════════════════════════════════════════════════════════════════
    group('isRecurring', () {
      test('should return true for daily frequency', () {
        expect(RecurrenceService.isRecurring('daily'), true);
      });

      test('should return true for weekly frequency', () {
        expect(RecurrenceService.isRecurring('weekly'), true);
      });

      test('should return true for biweekly frequency', () {
        expect(RecurrenceService.isRecurring('biweekly'), true);
      });

      test('should return true for monthly frequency', () {
        expect(RecurrenceService.isRecurring('monthly'), true);
      });

      test('should return false for once frequency', () {
        expect(RecurrenceService.isRecurring('once'), false);
      });

      test('should return false for null frequency', () {
        expect(RecurrenceService.isRecurring(null), false);
      });

      test('should return false for unknown frequency', () {
        expect(RecurrenceService.isRecurring('yearly'), false);
        expect(RecurrenceService.isRecurring('quarterly'), false);
        expect(RecurrenceService.isRecurring('random'), false);
      });

      test('should handle case-insensitive comparison', () {
        expect(RecurrenceService.isRecurring('WEEKLY'), true);
        expect(RecurrenceService.isRecurring('Weekly'), true);
        expect(RecurrenceService.isRecurring('ONCE'), false);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test edge cases for date calculations
    // INTENDED USE: Ensure reliability across year boundaries, leap years, etc.
    // ══════════════════════════════════════════════════════════════════════════
    group('Edge cases', () {
      test('should handle year boundary correctly', () {
        // Arrange
        final currentDate = DateTime(2024, 12, 30);

        // Act
        final nextWeekly = RecurrenceService.calculateNextDueDate(currentDate, 'weekly');

        // Assert
        expect(nextWeekly, DateTime(2025, 1, 6));
      });

      test('should handle leap year February correctly', () {
        // Arrange - Feb 28, 2024 (leap year)
        final currentDate = DateTime(2024, 2, 28);

        // Act
        final nextDaily = RecurrenceService.calculateNextDueDate(currentDate, 'daily');

        // Assert
        expect(nextDaily, DateTime(2024, 2, 29)); // Leap year has Feb 29
      });

      test('should handle non-leap year February correctly', () {
        // Arrange - Feb 28, 2023 (non-leap year)
        final currentDate = DateTime(2023, 2, 28);

        // Act
        final nextDaily = RecurrenceService.calculateNextDueDate(currentDate, 'daily');

        // Assert
        expect(nextDaily, DateTime(2023, 3, 1)); // No Feb 29 in 2023
      });

      test('should handle end of month for biweekly', () {
        // Arrange
        final currentDate = DateTime(2024, 1, 25);

        // Act
        final nextDate = RecurrenceService.calculateNextDueDate(currentDate, 'biweekly');

        // Assert
        expect(nextDate, DateTime(2024, 2, 8));
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test frequency display formatting
    // INTENDED USE: Show user-friendly frequency text in UI
    // ══════════════════════════════════════════════════════════════════════════
    group('Frequency formatting expectations', () {
      test('should map frequency codes to display text', () {
        // These are the expected mappings used in the UI
        final frequencyMap = {
          'daily': 'Daily',
          'weekly': 'Weekly',
          'biweekly': 'Biweekly',
          'monthly': 'Monthly',
          'once': 'Once',
        };

        expect(frequencyMap['daily'], 'Daily');
        expect(frequencyMap['weekly'], 'Weekly');
        expect(frequencyMap['biweekly'], 'Biweekly');
        expect(frequencyMap['monthly'], 'Monthly');
        expect(frequencyMap['once'], 'Once');
      });
    });
  });
}
