// lib/features/auth/presentation/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_planner/screens/auth/bloc/bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();

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
            child: Column(children: [
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 490,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration('Email'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration('Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: _courseController,
                          decoration: _buildInputDecoration('Course'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your course';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: _facultyController,
                          decoration: _buildInputDecoration('Faculty'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your faculty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                context.read<AppBloc>().add(
                                      AppSignUpWithEmail(
                                        _emailController.text,
                                        _passwordController.text,
                                        _nameController.text,
                                        int.tryParse(_courseController.text),
                                        _facultyController.text,
                                      ),
                                    );
                                // Navigate to home or profile screen after successful registration
                                Navigator.of(context)
                                    .pushReplacementNamed('/home');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Registration failed')),
                                );
                              }
                            }
                          },
                          child: const Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent.shade700,
                          ),
                          child: const Text(
                            'Alredy have an account? Sign in',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
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
}
