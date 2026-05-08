import 'package:flutter/material.dart';
import '../../jobs/screens/jobs_screen.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  String? errorMessage;

  Future<void> handleLogin() async {
  if (emailController.text.trim().isEmpty ||
      passwordController.text.trim().isEmpty) {
    setState(() {
      errorMessage = 'Email and password are required.';
    });
    return;
  }

  try {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    await authService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsScreen(),
      ),
    );
  } catch (error) {
    setState(() {
      errorMessage = error.toString().replaceAll('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Login to apply for jobs.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : handleLogin,
                  child: Text(
                    loading ? 'Logging in...' : 'Login',
                  ),
                ),
              ),

              const SizedBox(height: 16),

Center(
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        ),
      );
    },
    child: const Text('New user? Create account'),
  ),
), //register
            ],
          ),
        ),
      ),
    );
  }
}