import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

 final String baseUrl = 'http://10.0.2.2:5000/api';

Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );



  final data = jsonDecode(response.body);
  print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: $data');

  print('LOGIN RESPONSE: $data');

   if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

  throw Exception(data['message'] ?? 'Login failed');
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