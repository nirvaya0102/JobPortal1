import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_token_storage.dart';

void main() {
  group('TokenStorage (Mock)', () {
    setUp(() {
      MockTokenStorage.reset();
    });

    group('saveTokens', () {
      test('saves access token and refresh token', () async {
        const accessToken = 'access_token_123';
        const refreshToken = 'refresh_token_456';

        await MockTokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        expect(await MockTokenStorage.getAccessToken(), accessToken);
        expect(await MockTokenStorage.getRefreshToken(), refreshToken);
      });

      test('increments save call count', () async {
        expect(MockTokenStorage.saveCallCount, 0);

        await MockTokenStorage.saveTokens(
          accessToken: 'token1',
          refreshToken: 'refresh1',
        );

        expect(MockTokenStorage.saveCallCount, 1);

        await MockTokenStorage.saveTokens(
          accessToken: 'token2',
          refreshToken: 'refresh2',
        );

        expect(MockTokenStorage.saveCallCount, 2);
      });

      test('overwrites previous tokens', () async {
        await MockTokenStorage.saveTokens(
          accessToken: 'token1',
          refreshToken: 'refresh1',
        );

        expect(await MockTokenStorage.getAccessToken(), 'token1');

        await MockTokenStorage.saveTokens(
          accessToken: 'token2',
          refreshToken: 'refresh2',
        );

        expect(await MockTokenStorage.getAccessToken(), 'token2');
        expect(await MockTokenStorage.getRefreshToken(), 'refresh2');
      });

      test('tracks saved tokens history', () async {
        await MockTokenStorage.saveTokens(
          accessToken: 'token1',
          refreshToken: 'refresh1',
        );

        await MockTokenStorage.saveTokens(
          accessToken: 'token2',
          refreshToken: 'refresh2',
        );

        expect(MockTokenStorage.savedTokens, ['token1', 'token2']);
      });
    });

    group('getAccessToken', () {
      test('returns saved access token', () async {
        const token = 'test_access_token';

        await MockTokenStorage.saveTokens(
          accessToken: token,
          refreshToken: 'refresh',
        );

        final retrievedToken = await MockTokenStorage.getAccessToken();

        expect(retrievedToken, token);
      });

      test('returns null when no token saved', () async {
        final token = await MockTokenStorage.getAccessToken();

        expect(token, isNull);
      });
    });

    group('getRefreshToken', () {
      test('returns saved refresh token', () async {
        const refreshToken = 'test_refresh_token';

        await MockTokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: refreshToken,
        );

        final retrieved = await MockTokenStorage.getRefreshToken();

        expect(retrieved, refreshToken);
      });

      test('returns null when no token saved', () async {
        final token = await MockTokenStorage.getRefreshToken();

        expect(token, isNull);
      });
    });

    group('clearTokens', () {
      test('clears both access and refresh tokens', () async {
        await MockTokenStorage.saveTokens(
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        expect(await MockTokenStorage.getAccessToken(), 'token');
        expect(await MockTokenStorage.getRefreshToken(), 'refresh');

        await MockTokenStorage.clearTokens();

        expect(await MockTokenStorage.getAccessToken(), isNull);
        expect(await MockTokenStorage.getRefreshToken(), isNull);
      });

      test('increments clear call count', () async {
        expect(MockTokenStorage.clearCallCount, 0);

        await MockTokenStorage.clearTokens();

        expect(MockTokenStorage.clearCallCount, 1);

        await MockTokenStorage.clearTokens();

        expect(MockTokenStorage.clearCallCount, 2);
      });

      test('tracks cleared tokens history', () async {
        await MockTokenStorage.clearTokens();
        await MockTokenStorage.clearTokens();

        expect(MockTokenStorage.clearedTokens, ['cleared', 'cleared']);
      });
    });

    group('reset', () {
      test('resets all state', () async {
        await MockTokenStorage.saveTokens(
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        expect(MockTokenStorage.saveCallCount, 1);
        expect(MockTokenStorage.accessToken, 'token');

        MockTokenStorage.reset();

        expect(MockTokenStorage.accessToken, isNull);
        expect(MockTokenStorage.refreshToken, isNull);
        expect(MockTokenStorage.saveCallCount, 0);
        expect(MockTokenStorage.clearCallCount, 0);
        expect(MockTokenStorage.savedTokens, isEmpty);
        expect(MockTokenStorage.clearedTokens, isEmpty);
      });
    });

    group('Integration', () {
      test('complete token lifecycle', () async {
        // Initially no tokens
        expect(await MockTokenStorage.getAccessToken(), isNull);

        // Save tokens
        await MockTokenStorage.saveTokens(
          accessToken: 'new_token',
          refreshToken: 'new_refresh',
        );

        expect(await MockTokenStorage.getAccessToken(), 'new_token');
        expect(await MockTokenStorage.getRefreshToken(), 'new_refresh');

        // Update tokens
        await MockTokenStorage.saveTokens(
          accessToken: 'updated_token',
          refreshToken: 'updated_refresh',
        );

        expect(await MockTokenStorage.getAccessToken(), 'updated_token');

        // Clear tokens
        await MockTokenStorage.clearTokens();

        expect(await MockTokenStorage.getAccessToken(), isNull);
        expect(await MockTokenStorage.getRefreshToken(), isNull);
      });

      test('tracks all operations', () async {
        await MockTokenStorage.saveTokens(
          accessToken: 'token1',
          refreshToken: 'refresh1',
        );
        await MockTokenStorage.saveTokens(
          accessToken: 'token2',
          refreshToken: 'refresh2',
        );
        await MockTokenStorage.clearTokens();

        expect(MockTokenStorage.saveCallCount, 2);
        expect(MockTokenStorage.clearCallCount, 1);
        expect(MockTokenStorage.savedTokens.length, 2);
      });
    });
  });
}
