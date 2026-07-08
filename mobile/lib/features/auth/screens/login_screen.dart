import 'package:flutter/material.dart';
import '../../jobs/screens/candidate_main_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import '../../employer/screens/employer_dashboard_screen.dart';
import '../../../core/storage/user_storage.dart';
import '../../../shared/widgets/premium_text_field.dart';
import '../../../shared/widgets/role_toggle.dart';

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
  bool isCandidate = true; // Cosmetic toggle for login
  bool rememberMe = false; // Remember me functionality

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter email and password.');
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final loginData = await authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final data = loginData['data'] ?? loginData;
      final user = data['user'];
      final token = data['token'] ?? data['accessToken'];

      if (token == null) {
        throw Exception('Token not found in login response');
      }

      if (user['role'] == 'ADMIN') {
        await UserStorage.saveUser(
          id: (user['id'] ?? '').toString(),
          name: (user['name'] ?? '').toString(),
          role: (user['role'] ?? '').toString(),
          location: (user['location'] ?? '').toString(),
          email: (user['email'] ?? email).toString(),
          phone: (user['phone'] ?? '').toString(),
        );

        if (rememberMe) {
          await UserStorage.saveRememberMeEmail(email);
        } else {
          await UserStorage.clearRememberMeEmail();
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(
              name: (user['name'] ?? 'Admin').toString(),
            ),
          ),
        );
      } else if (user['role'] == 'EMPLOYER') {
        await UserStorage.saveUser(
          id: (user['id'] ?? '').toString(),
          name: (user['name'] ?? '').toString(),
          role: (user['role'] ?? '').toString(),
          location: (user['companyLocation'] ?? '').toString(),
          email: (user['email'] ?? email).toString(),
          phone: (user['phone'] ?? '').toString(),
        );

        // AUTH-006: Remember me - save email for next login
        if (rememberMe) {
          await UserStorage.saveRememberMeEmail(email);
        } else {
          await UserStorage.clearRememberMeEmail();
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EmployerDashboardScreen(token: token, name: user['name']),
          ),
        );
      } else {
        await UserStorage.saveUser(
          id: (user['id'] ?? '').toString(),
          name: (user['name'] ?? '').toString(),
          role: (user['role'] ?? '').toString(),
          location: (user['location'] ?? '').toString(),
          email: (user['email'] ?? email).toString(),
          phone: (user['phone'] ?? '').toString(),
        );

        // AUTH-006: Remember me - save email for next login
        if (rememberMe) {
          await UserStorage.saveRememberMeEmail(email);
        } else {
          await UserStorage.clearRememberMeEmail();
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CandidateMainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // AUTH-006: Load remembered email on init
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final savedEmail = await UserStorage.getRememberMeEmail();
    if (savedEmail != null && mounted) {
      setState(() {
        emailController.text = savedEmail;
        rememberMe = true;
      });
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
    const primaryBlue = Color(0xFF000B5E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFF0F2FF),
              Color(0xFFFDFBFE),
              Color(0xFFFEF3FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rojgar Kendra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue to your\nprofessional journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    RoleToggle(
                      isCandidate: isCandidate,
                      onChanged: (val) => setState(() => isCandidate = val),
                    ),
                    const SizedBox(height: 28),

                    PremiumTextField(
                      label: 'Email Address',
                      hintText: 'john.doe@example.com',
                      prefixIcon: Icons.mail_outline,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    PremiumTextField(
                      label: 'Password',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !showPassword,
                      controller: passwordController,
                      suffixIcon: showPassword ? Icons.visibility : Icons.visibility_off,
                      onSuffixTap: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                      topTrailing: InkWell(
                        onTap: () {},
                        child: Text(
                          'Forgot?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AUTH-006: Remember me checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() => rememberMe = value ?? false);
                          },
                          activeColor: primaryBlue,
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create\nAccount',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
