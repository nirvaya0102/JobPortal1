import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      final accessToken = data['data']?['accessToken'] ?? data['accessToken'];
      final refreshToken = data['data']?['refreshToken'] ?? data['refreshToken'];

      if (accessToken == null) {
        throw Exception('Access token missing in response');
      }

      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? e.message ?? 'Login failed';
      throw Exception(message);
    }
  }


Future<void> register({
  required String name,
  required String email,
  required String password,
  required String role,
}) async {
  await ApiClient.dio.post(
    '/auth/register',
    data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    },
  );
}


  Future<void> logout() async {
    await TokenStorage.clearTokens();
  }


}