// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_planner/screens/auth/bloc/bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: 120),
        child: SizedBox(
          width: double.infinity,
          height: 700,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Let`s make plan!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Будь ласка, введіть email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Будь ласка, введіть дійсний email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration('Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Будь ласка, введіть пароль';
                            }
                            if (value.length < 6) {
                              return 'Пароль має бути не менше 6 символів';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => context
                                    .read<AppBloc>()
                                    .add(AppLoginWithEmail(
                                      _emailController.text,
                                      _passwordController.text,
                                    )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent.shade700,
                          ),
                          child: const Text(
                            'Don`t have an account? Sign up',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                    height: 40, thickness: 1, indent: 20, endIndent: 20),
                Text(
                  'Or use to log in',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialSignInButton(
                        context: context,
                        label: 'Google',
                        icon: 'assets/google.png',
                        onPressed: () =>
                            context.read<AppBloc>().add(AppSignInWithGoogle()),
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade100,
                      ),
                      Spacer(),
                      _buildSocialSignInButton(
                        context: context,
                        label: 'Facebook',
                        icon: 'assets/facebook.png',
                        onPressed: () => context
                            .read<AppBloc>()
                            .add(AppSignInWithFacebook()),
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2),
      ),
      fillColor: Colors.grey[50],
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSocialSignInButton({
    required BuildContext context,
    required String label,
    required String icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: const Size(100, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : BorderSide.none,
        ),
        elevation: 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, height: 24, width: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
