import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'features/auth/screens/auth_check_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/jobs/screens/jobs_screen.dart';

void main() {
 ApiClient.setupInterceptors();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/auth-check',

      routes: {
        '/auth-check': (context) => const AuthCheckScreen(),

        '/login': (context) => const LoginScreen(),

        '/home': (context) => const JobsScreen(),
      
      },
    );
  }
}