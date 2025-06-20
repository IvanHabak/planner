// lib/features/profile/presentation/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/screens/auth/bloc/bloc.dart';
import '/models/user.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _courseController;
  late TextEditingController _facultyController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    final userModel = context.read<AppBloc>().state.user;

    _nameController = TextEditingController(text: userModel.name ?? '');
    _emailController = TextEditingController(text: userModel.email ?? '');
    _courseController =
        TextEditingController(text: userModel.course?.toString() ?? '');
    _facultyController = TextEditingController(text: userModel.faculty ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _facultyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Використовуємо BlocListener для реакції на оновлення стану AppBloc
    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        // Якщо профіль успішно оновлено, повертаємось на попередній екран
        if (state.status == 'authenticated') {
          // Можна додати SnackBar для підтвердження
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профіль успішно оновлено!')),
          );
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // Якщо дані користувача ще не завантажені або порожні, показуємо індикатор
          if (state.user.uid!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blueAccent.shade100,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    TextFormField(
                      controller: _courseController,
                      decoration: const InputDecoration(labelText: 'Course'),
                      keyboardType: TextInputType.number, // Для курсу
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your course';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number for course';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _facultyController, // Змінено на faculty
                      decoration: const InputDecoration(labelText: 'Faculty'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your faculty'
                          : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      enabled: false, // Email поле вимкнено для редагування
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your email'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Отримуємо поточний UID користувача
                          final currentUserId =
                              context.read<AppBloc>().state.user.uid;

                          // Створюємо оновлений об'єкт UserModel
                          final updatedUser = state.user.copyWith(
                            uid: currentUserId,
                            name: _nameController.text.trim(),
                            course: int.tryParse(_courseController.text.trim()),
                            faculty: _facultyController.text.trim(),
                          );

                          // Відправляємо подію оновлення профілю в AppBloc
                          context.read<AppBloc>().add(
                                AppUserProfileUpdated(updatedUser),
                              );
                        }
                      },
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
