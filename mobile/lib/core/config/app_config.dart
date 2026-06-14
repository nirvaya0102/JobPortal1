import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    final override = _normalizeBaseUrl(_apiBaseUrlOverride);
    if (override != null) {
      return override;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api/';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000/api/';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000/api/';
    }
  }

  static String? _normalizeBaseUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed;
    if (!normalized.endsWith('/')) {
      normalized = '$normalized/';
    }
    if (!normalized.endsWith('api/')) {
      normalized = '${normalized}api/';
    }

    return normalized;
  }
}
