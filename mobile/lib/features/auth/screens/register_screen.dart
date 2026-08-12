import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final authService = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final companyNameController = TextEditingController();
  final companyLocationController = TextEditingController();
  final companyDescriptionController = TextEditingController();
  final companyWebsiteController = TextEditingController();
  final adminRegistrationCodeController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool acceptedTerms = false;

  String role = 'CANDIDATE';
  String? errorMessage;

  Future<void> handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final companyName = companyNameController.text.trim();
    final companyLocation = companyLocationController.text.trim();
    final companyDescription = companyDescriptionController.text.trim();
    final companyWebsite = companyWebsiteController.text.trim();
    final adminRegistrationCode = adminRegistrationCodeController.text.trim();

    if (role == 'EMPLOYER') {
      if (companyName.isEmpty || companyLocation.isEmpty) {
        setState(() {
          errorMessage = 'Company name and location are required for employer.';
        });
        return;
      }

      if (companyWebsite.isNotEmpty &&
          !(companyWebsite.startsWith('http://') ||
              companyWebsite.startsWith('https://'))) {
        setState(() {
          errorMessage = 'Company website must start with http:// or https://.';
        });
        return;
      }
    }

    if (role == 'ADMIN' && adminRegistrationCode.isEmpty) {
      setState(() {
        errorMessage = 'Admin registration code is required.';
      });
      return;
    }

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'All fields are required.';
      });
      return;
    }

    if (phone.length < 7) {
      setState(() {
        errorMessage = 'Please enter a valid phone number.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        errorMessage = 'Please enter a valid email.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        errorMessage = 'Password must be at least 8 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (!acceptedTerms) {
      setState(() {
        errorMessage = 'Please accept the terms.';
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      await authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        companyName: role == 'EMPLOYER' ? companyName : null,
        companyLocation: role == 'EMPLOYER' ? companyLocation : null,
        companyDescription: role == 'EMPLOYER' ? companyDescription : null,
        companyWebsite: role == 'EMPLOYER' ? companyWebsite : null,
        adminRegistrationCode:
            role == 'ADMIN' ? adminRegistrationCode : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful. Please verify your email.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    companyNameController.dispose();
    companyLocationController.dispose();
    companyDescriptionController.dispose();
    companyWebsiteController.dispose();
    adminRegistrationCodeController.dispose();
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
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Register to apply for jobs.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

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
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
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
                      showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: confirmPasswordController,
                obscureText: !showPassword,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CANDIDATE',
                    child: Text('Candidate'),
                  ),
                  DropdownMenuItem(
                    value: 'EMPLOYER',
                    child: Text('Employer'),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      role = value;
                    });
                  }
                },
              ),

              if (role == 'EMPLOYER') ...[
                const SizedBox(height: 16),

                TextField(
                  controller: companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: companyLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Company Location',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: companyDescriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Company Description',
                    hintText: 'Briefly describe your company',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: companyWebsiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Company Website',
                    hintText: 'https://company.com',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              if (role == 'ADMIN') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: adminRegistrationCodeController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Admin Registration Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    acceptedTerms = value ?? false;
                  });
                },
                title: const Text('I agree to the terms and conditions'),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : handleRegister,
                  child: Text(
                    loading ? 'Creating account...' : 'Register',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
