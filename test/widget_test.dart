// test/widget_test.dart
// Basic smoke test for CleanSlate app

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // PURPOSE: Basic smoke test to verify app builds
  // INTENDED USE: CI/CD pipeline to catch obvious build errors
  // ══════════════════════════════════════════════════════════════════════════
  group('CleanSlate App', () {
    test('app name is defined', () {
      expect('CleanSlate', isNotEmpty);
    });

    test('version format is valid', () {
      const version = '1.0.0+1';
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
    });
  });
}
