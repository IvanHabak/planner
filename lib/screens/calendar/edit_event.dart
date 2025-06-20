import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/models/event_type.dart';
import '/models/event.dart';

import './bloc/bloc.dart';

class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late EventType _selectedType;
  File? _imageFile;
  String? _currentImageUrl;
  List<File> _newAttachments = [];
  List<String> _currentAttachmentUrls = [];
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    // Ініціалізуємо контролери та змінні стану даними з існуючої події
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description ?? '';
    _locationController.text = widget.event.location ?? '';
    _selectedDate = widget.event.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.event.dateTime);
    _selectedType = widget.event.type;
    _currentImageUrl = widget.event.imageUrl;
    _currentAttachmentUrls =
        List.from(widget.event.attachments); // Створюємо копію
    _isPublic = widget.event.isPublic;
  }

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
        _currentImageUrl = null;
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
        _newAttachments.add(File(result.files.single.path!));
      });
    }
  }

  void _removeNewAttachment(File file) {
    setState(() {
      _newAttachments.remove(file);
    });
  }

  void _removeCurrentAttachment(String url) {
    setState(() {
      _currentAttachmentUrls.remove(url);
    });
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      final updatedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Використовуємо copyWith для створення нового об'єкта Event
      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: updatedDateTime,
        location: _locationController.text.trim(),
        type: _selectedType,
        isPublic: _isPublic,
        imageUrl: _imageFile != null ? null : _currentImageUrl,
        attachments: _currentAttachmentUrls,
      );

      context.read<EventBloc>().add(
            UpdateEvent(
              event: updatedEvent,
              newAttachments: _newAttachments,
              newImage: _imageFile,
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
          'Edit Event',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent.shade100,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          if (state.status == EventStatus.loading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updating event...')),
            );
          } else if (state.status == EventStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event updated successfully!')),
            );
            Navigator.pop(context);
          } else if (state.status == EventStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to update event: ${state.errorMessage}')),
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

                // Відображення поточної/нової картинки
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
                        onPressed: () => setState(() {
                          _imageFile = null;
                          _currentImageUrl = null;
                        }),
                      ),
                    ],
                  )
                else if (_currentImageUrl != null &&
                    _currentImageUrl!.isNotEmpty)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_currentImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        onPressed: () =>
                            setState(() => _currentImageUrl = null),
                      ),
                    ],
                  ),
                if (_imageFile == null &&
                    (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                  _buildActionButton(
                    onPressed: _pickImage,
                    icon: Icons.image,
                    label: 'Add Event Image',
                    backgroundColor: Colors.blueAccent.shade400,
                  ),
                const SizedBox(height: 10),

                // Відображення існуючих вкладень
                ..._currentAttachmentUrls
                    .map((url) => _buildAttachmentUrlTile(url)),
                // Відображення нових вкладень
                ..._newAttachments
                    .map((file) => _buildAttachmentFileTile(file)),
                _buildActionButton(
                  onPressed: _pickAttachment,
                  icon: Icons.attach_file,
                  label: 'Add Attachment',
                  backgroundColor: Colors.blueAccent.shade400,
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  onPressed: _updateEvent,
                  label: 'Save Changes',
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
        border: Border.all(
          color: _isPublic ? Colors.blueAccent : Colors.grey.shade300,
          width: _isPublic ? 2.0 : 1.0,
        ),
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

  Widget _buildAttachmentFileTile(File file) {
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
            onPressed: () => _removeNewAttachment(file),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentUrlTile(String url) {
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
              url.split('/').last,
              style: TextStyle(color: Colors.blueAccent.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blueAccent),
            onPressed: () => _removeCurrentAttachment(url),
          ),
        ],
      ),
    );
  }
}
