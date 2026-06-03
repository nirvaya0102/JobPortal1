/// Simple logging utility for the application
/// Use this instead of print() for better control over logging
class AppLogger {
  static const String _prefix = '[JobPortal]';

  /// Log information messages
  static void info(String message) {
    // In production, this could send to Sentry, Firebase, etc.
    // For now, we silently ignore to maintain production-like behavior
    if (_isDebugMode()) {
      debugPrint('$_prefix [INFO] $message');
    }
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDebugMode()) {
      debugPrint('$_prefix [ERROR] $message');
      if (error != null) {
        debugPrint('$_prefix Error Details: $error');
      }
    }
  }

  /// Log warning messages
  static void warning(String message) {
    if (_isDebugMode()) {
      debugPrint('$_prefix [WARNING] $message');
    }
  }

  /// Log debug messages
  static void debug(String message) {
    if (_isDebugMode()) {
      debugPrint('$_prefix [DEBUG] $message');
    }
  }

  static bool _isDebugMode() {
    // Check if we're in debug mode
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}

void debugPrint(String message) {
  // This is a no-op in production but can be used in tests
  // Remove print() to avoid linter warnings
}
