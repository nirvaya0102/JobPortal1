import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      // Login request completed

      final responseData = data['data'] ?? data;
      final token = responseData['token'] ?? responseData['accessToken'];
      final refreshToken = responseData['refreshToken'] ?? '';

      if (token != null) {
        await TokenStorage.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      }

      return data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? companyName,
    String? companyLocation,
  }) async {
    await ApiClient.dio.post(
      'auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'companyName': companyName,
        'companyLocation': companyLocation,
      },
    );
  }

  Future<void> logout() async {
    try {
      await ApiClient.dio.post('auth/logout'); // Optional: backend logout
    } catch (_) {}
    await TokenStorage.clearTokens();
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        await ApiClient.dio.patch('auth/fcm-token', data: {'fcmToken': token});
      }
    } catch (e) {
      // FCM token sync failed
    }
  }

  String _getErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Check your internet or API URL.';
    }

    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        final errors = responseData['errors'];
        if (errors is List && errors.isNotEmpty) {
          final firstError = errors.first;
          if (firstError is Map<String, dynamic>) {
            final fieldMessage = firstError['message'];
            if (fieldMessage is String && fieldMessage.trim().isNotEmpty) {
              return fieldMessage;
            }
          }
        }
        return message;
      }
    }

    return 'Login failed. Please try again.';
  }
}
