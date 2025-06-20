import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/bloc/bloc.dart';
import '/models/event_type.dart';
import '/models/event.dart';
import './bloc/bloc.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  EventType _selectedType = EventType.lecture;
  File? _imageFile;
  List<File> _attachments = [];
  bool _isPublic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );
    if (result != null) {
      setState(() {
        _attachments.add(File(result.files.single.path!));
      });
    }
  }

  void _removeAttachment(File file) {
    setState(() {
      _attachments.remove(file);
    });
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      // Отримуємо UID поточного користувача з AppBloc
      final user = context.read<AppBloc>().state.user;

      if (user.uid == null) {
        // Обробка випадку, коли користувач не залогінений
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create an event.')),
        );
        return;
      }

      final event = Event(
        id: '', // ID буде встановлено в EventBloc / EventRepository
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        location: _locationController.text.trim(),
        creatorId: user.uid!,
        type: _selectedType,
        isPublic: _isPublic,
      );

      // Відправляємо подію AddEvent до EventBloc
      context.read<EventBloc>().add(
            AddEvent(
              event: event,
              image: _imageFile,
              attachments: _attachments,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Create New Event',
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
      body: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          // Слухаємо зміни стану EventBloc
          if (state.status == EventStatus.loading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Creating event...')),
            );
          } else if (state.status == EventStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );
            Navigator.pop(context);
          } else if (state.status == EventStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to create event: ${state.errorMessage}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Event Details'),
                const SizedBox(height: 10),
                _buildTextFormField(
                  controller: _titleController,
                  labelText: 'Event Title',
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                _buildDropdownButtonFormField<EventType>(
                  value: _selectedType,
                  items: EventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, color: type.color),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                  labelText: 'Event Type',
                ),
                const SizedBox(height: 15),
                _buildTextFormField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Date & Time'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePickerButton(
                        onPressed: _selectDate,
                        label: 'Date',
                        value: DateFormat.yMd().format(_selectedDate),
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateTimePickerButton(
                        onPressed: _selectTime,
                        label: 'Time',
                        value: _selectedTime.format(context),
                        icon: Icons.access_time,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPublicEventSwitch(),
                const SizedBox(height: 20),
                _buildSectionTitle('Location'),
                const SizedBox(height: 10),
                _buildTextFormField(
                  controller: _locationController,
                  labelText: 'Location',
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Media & Attachments'),
                const SizedBox(height: 10),
                if (_imageFile != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                    ],
                  ),
                if (_imageFile == null)
                  _buildActionButton(
                    onPressed: _pickImage,
                    icon: Icons.image,
                    label: 'Add Image',
                    backgroundColor: Colors.blueAccent.shade400,
                  ),
                const SizedBox(height: 10),
                ..._attachments.map((file) => _buildAttachmentTile(file)),
                _buildActionButton(
                  onPressed: _pickAttachment,
                  icon: Icons.attach_file,
                  label: 'Add Attachment',
                  backgroundColor: Colors.blueAccent.shade400,
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  onPressed: _submitEvent,
                  label: 'Create Event',
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  isPrimary: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets (ваші існуючі методи, без змін)
  Widget _buildPublicEventSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Public Event',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (bool value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: validator,
      maxLines: maxLines,
      cursorColor: Colors.blueAccent,
    );
  }

  Widget _buildDropdownButtonFormField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String labelText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      iconEnabledColor: Colors.blueAccent,
      iconDisabledColor: Colors.grey,
    );
  }

  Widget _buildDateTimePickerButton({
    required VoidCallback onPressed,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.blueAccent,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPrimary ? 12 : 25),
        ),
        elevation: isPrimary ? 3 : 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(File file) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.path.split('/').last,
              style: TextStyle(color: Colors.blueAccent.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blueAccent),
            onPressed: () => _removeAttachment(file),
          ),
        ],
      ),
    );
  }
}
