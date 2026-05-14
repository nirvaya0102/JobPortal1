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
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN RESPONSE: $data');

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
    throw Exception(e.response?.data['message'] ?? 'Login failed');
  }
}


Future<void> register({
  required String name,
  required String email,
  required String password,
  required String role,
    String? companyName,
    String? companyLocation,
}) async {
  await ApiClient.dio.post(
    'auth/register',
    data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
       if (companyName != null) 'companyName': companyName,
          if (companyLocation != null) 'companyLocation': companyLocation,
    },
  );
}


  Future<void> logout() async {
    await TokenStorage.clearTokens();
  }


}