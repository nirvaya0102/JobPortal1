import 'package:dio/dio.dart';
import 'dart:async';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json', 'x-client-type': 'mobile'},
    ),
  );

  static bool _isRefreshing = false;
  static Completer<String?>? _refreshCompleter;

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

          // Avoid infinite loops if refresh itself is unauthorized.
          final path = error.requestOptions.path;
          if (path.contains('auth/refresh')) {
            await TokenStorage.clearTokens();
            return handler.reject(error);
          }

          final refreshToken = await TokenStorage.getRefreshToken();

          if (refreshToken == null || refreshToken.isEmpty) {
            await TokenStorage.clearTokens();
            return handler.reject(error);
          }

          if (_isRefreshing) {
            final token = await _refreshCompleter?.future;
            if (token == null || token.isEmpty) {
              await TokenStorage.clearTokens();
              return handler.reject(error);
            }

            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          }

          _isRefreshing = true;
          _refreshCompleter = Completer<String?>();

          String? newAccessToken;
          try {
            newAccessToken = await _refreshAccessToken(refreshToken);
            _refreshCompleter?.complete(newAccessToken);
          } catch (_) {
            _refreshCompleter?.complete(null);
            await TokenStorage.clearTokens();
          } finally {
            _isRefreshing = false;
          }

          if (newAccessToken == null || newAccessToken.isEmpty) {
            return handler.reject(error);
          }

          final requestOptions = error.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
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
      'auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data['data'];
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

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
