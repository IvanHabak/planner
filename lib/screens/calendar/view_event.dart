import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/screens/calendar/edit_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '/models/event.dart';
import '/models/event_type.dart';

import './bloc/bloc.dart';
import '.././auth/bloc/bloc.dart';

class ViewEventPage extends StatelessWidget {
  final Event event;

  const ViewEventPage({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select((AppBloc bloc) => bloc.state.user.uid);

    final bool isCurrentUserCreator = event.creatorId == currentUserId;

    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat.MMMd();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          event.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent.shade100,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          if (isCurrentUserCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventPage(event: event),
                  ),
                );
              },
            ),
          // Кнопка видалення/відписки
          if (currentUserId !=
              null) // Показуємо кнопку, якщо користувач залогінений
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteOrRemove(
                  context, isCurrentUserCreator, currentUserId),
            ),
        ],
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state.status == EventStatus.success &&
              !state.userEvents.any((e) => e.id == event.id)) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Event updated or deleted successfully!')),
            );
          } else if (state.status == EventStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action failed: ${state.errorMessage}')),
            );
          }
        },
        builder: (context, state) {
          final currentEvent = state.userEvents.firstWhere(
            (e) => e.id == event.id,
            orElse: () => event,
          );

          // Якщо подія була видалена, або її не існує
          // if (currentEvent == event &&
          //     !state.userEvents.any((e) => e.id == event.id) &&
          //     state.status != EventStatus.loading) {
          //   print(state.userEvents.toString());
          //   return const Center(
          //       child: Text('Event not found or has been deleted.'));
          // }

          //     if (currentEvent == null && state.status != EventStatus.loading) {
          //   return const Center(child: Text('Подію не знайдено або її було видалено.'));
          // }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image display
                if (currentEvent.imageUrl != null &&
                    currentEvent.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      currentEvent.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey[400], size: 50),
                        ),
                      ),
                    ),
                  )
                else
                  // Замість Spacer() використовуємо SizedBox, щоб уникнути помилок рендерингу в Column
                  SizedBox(height: 0),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const SizedBox(width: 10),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      text:
                          '${dateFormat.format(currentEvent.dateTime)}, ${timeFormat.format(currentEvent.dateTime)}',
                    ),
                    const Spacer(),
                    currentEvent.location == null ||
                            currentEvent.location!.isEmpty
                        ? const SizedBox(
                            width:
                                0) // Якщо немає локації, не відображаємо Spacer
                        : _buildInfoRow(
                            icon: Icons.location_on,
                            text: currentEvent.location!,
                          ),
                    const SizedBox(width: 10),
                  ],
                ),

                const SizedBox(height: 16),
                _buildInfoTile(
                  icon: currentEvent.type.icon,
                  value: currentEvent.type.displayName,
                  iconColor: currentEvent.type.color,
                ),
                const SizedBox(height: 10),
                _buildInfoTile(
                  icon: currentEvent.isPublic ? Icons.public : Icons.lock,
                  value:
                      currentEvent.isPublic ? 'Public Event' : 'Private Event',
                  iconColor: currentEvent.isPublic ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentEvent.description ??
                        'No description provided for this event.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                  ),
                ),
                const SizedBox(height: 20),

                if (currentEvent.attachments != null &&
                    currentEvent.attachments!.isNotEmpty) ...[
                  _buildSectionTitle('Attachments'),
                  const SizedBox(height: 10),
                  ...currentEvent.attachments!
                      .map((url) => _buildAttachmentDisplayTile(context, url)),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets (без змін, якщо не використовують Provider або EventRepository напряму) ---

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String value,
    Color iconColor = Colors.blueAccent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  Widget _buildAttachmentDisplayTile(BuildContext context, String url) {
    String fileName = Uri.decodeComponent(url.split('/').last.split('?').first);

    if (fileName.contains('%2F')) {
      fileName = fileName.substring(fileName.lastIndexOf('%2F') + 3);
    }

    IconData fileIcon = Icons.insert_drive_file;
    if (fileName.toLowerCase().endsWith('.pdf')) {
      fileIcon = Icons.picture_as_pdf;
    } else if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      fileIcon = Icons.description;
    } else if (fileName.toLowerCase().endsWith('.ppt') ||
        fileName.toLowerCase().endsWith('.pptx')) {
      fileIcon = Icons.slideshow;
    } else if (fileName.toLowerCase().endsWith('.zip') ||
        fileName.toLowerCase().endsWith('.rar')) {
      fileIcon = Icons.folder_zip;
    } else if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png')) {
      fileIcon = Icons.image;
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      fileIcon = Icons.text_snippet;
    }

    return InkWell(
      onTap: () async {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не вдалося відкрити файл "$fileName".')),
            );
          }
        } catch (e) {
          debugPrint('Помилка при спробі відкрити URL: $e');
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Виникла помилка при відкритті файлу "$fileName".')),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.shade100),
        ),
        child: Row(
          children: [
            Icon(fileIcon, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(color: Colors.blueAccent.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrRemove(
      BuildContext context, bool isCurrentUserCreator, String? currentUserId) {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated.')));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isCurrentUserCreator ? 'Delete Event' : 'Remove Event'),
        content: Text(
          isCurrentUserCreator
              ? 'Are you sure you want to permanently delete this event for all users?'
              : 'Are you sure you want to remove this event from your calendar? It will still be visible to other users.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (isCurrentUserCreator) {
                context.read<EventBloc>().add(DeleteEvent(event.id));
              } else {
                context
                    .read<EventBloc>()
                    .add(LeaveEvent(eventId: event.id, userId: currentUserId));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isCurrentUserCreator ? 'Delete' : 'Remove for me'),
          ),
        ],
      ),
    );
  }
}
