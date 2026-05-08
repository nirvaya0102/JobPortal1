import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:5000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'x-client-type': 'mobile',
      },
    ),
  );

  static bool _isRefreshing = false;
  static final List<Function(String)> _retryQueue = [];

  static void setupInterceptors() {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await TokenStorage.getAccessToken();

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          return handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final refreshToken = await TokenStorage.getRefreshToken();

          if (refreshToken == null || refreshToken.isEmpty) {
            await TokenStorage.clearTokens();
            return handler.reject(error);
          }

          if (_isRefreshing) {
            _retryQueue.add((newAccessToken) async {
              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final response = await dio.fetch(requestOptions);
              handler.resolve(response);
            });

            return;
          }

          _isRefreshing = true;

          try {
            final newAccessToken = await _refreshAccessToken(refreshToken);

            for (final retry in _retryQueue) {
              retry(newAccessToken);
            }

            _retryQueue.clear();

            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (_) {
            _retryQueue.clear();
            await TokenStorage.clearTokens();
            return handler.reject(error);
          } finally {
            _isRefreshing = false;
          }
        },
      ),
    );
  }

  static Future<String> _refreshAccessToken(String refreshToken) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'x-client-type': 'mobile',
        },
      ),
    );

    final response = await refreshDio.post(
      '/auth/refresh-token',
      data: {
        'refreshToken': refreshToken,
      },
    );

    final newAccessToken = response.data['accessToken'];
    final newRefreshToken = response.data['refreshToken'];

    if (newAccessToken == null) {
      throw Exception('Access token not found');
    }

    await TokenStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? refreshToken,
    );

    return newAccessToken;
  }
}