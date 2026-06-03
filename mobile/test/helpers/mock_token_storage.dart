import 'package:flutter_test/flutter_test.dart';

/// Mock implementation of TokenStorage for testing
class MockTokenStorage {
  static String? _accessToken;
  static String? _refreshToken;
  static List<String> savedTokens = [];
  static List<String> clearedTokens = [];
  static int saveCallCount = 0;
  static int clearCallCount = 0;

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    saveCallCount++;
    savedTokens.add(accessToken);
  }

  static Future<String?> getAccessToken() async {
    return _accessToken;
  }

  static Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    clearCallCount++;
    clearedTokens.add('cleared');
  }

  static void reset() {
    _accessToken = null;
    _refreshToken = null;
    saveCallCount = 0;
    clearCallCount = 0;
    savedTokens.clear();
    clearedTokens.clear();
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
}
