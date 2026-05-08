import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';

class JobPortalApp extends StatelessWidget {
  const JobPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobPortal',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}