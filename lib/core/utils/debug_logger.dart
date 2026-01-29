// lib/core/utils/debug_logger.dart
// Debug-only logger that is stripped in release builds.

import 'package:flutter/foundation.dart';

/// Logs a message only in debug mode. No-op in release builds.
void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
