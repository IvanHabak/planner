import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import './view_event.dart';
import '/models/event.dart';
import '/models/event_type.dart';

import './bloc/bloc.dart';
import '.././auth/bloc/bloc.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final bool showJoinButton;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat.MMMd();

    final currentUserId = context.select((AppBloc bloc) => bloc.state.user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => ViewEventPage(event: event)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400], size: 50),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 10,
                ),
              // Container(
              //   height: 100,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[200],
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Center(
              //     child: Text(
              //       'No image',
              //       style: TextStyle(color: Colors.grey[600]),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Icon(
                    event.type.icon,
                    color: event.type.color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (event.isPublic)
                    const Icon(Icons.public, size: 16, color: Colors.grey)
                ],
              ),
              const SizedBox(height: 8),
              if (event.description != null && event.description!.isNotEmpty)
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    text: dateFormat.format(event.dateTime),
                  ),
                  const SizedBox(width: 16),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    text: timeFormat.format(event.dateTime),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.location != null && event.location!.isNotEmpty)
                _buildInfoRow(
                  icon: Icons.location_on,
                  text: event.location!,
                ),

              // Відображаємо кнопки Приєднатись/Відписатись тільки якщо:
              // 1. showJoinButton = true
              // 2. currentUserId не null (користувач залогінений)
              // 3. currentUserId не є creatorId (не сам собі)
              if (showJoinButton &&
                  currentUserId != null &&
                  event.creatorId != currentUserId) ...[
                const SizedBox(height: 12),
                BlocSelector<EventBloc, EventState, bool>(
                  selector: (state) {
                    final updatedEvent = state.userEvents.firstWhere(
                      (e) => e.id == event.id,
                      orElse: () => event,
                    );
                    // Перевіряємо, чи поточний користувач є учасником оновленої події
                    return updatedEvent.participants.contains(currentUserId);
                  },
                  builder: (context, isUserParticipant) {
                    return Row(
                      children: [
                        isUserParticipant
                            ? Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.read<EventBloc>().add(
                                          LeaveEvent(
                                              eventId: event.id,
                                              userId: currentUserId!),
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Ви відписались від "${event.title}"')),
                                    );
                                  },
                                  child: const Text('Відписатись'),
                                ),
                              )
                            : Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.read<EventBloc>().add(
                                          JoinEvent(
                                              eventId: event.id,
                                              userId: currentUserId!),
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Ви приєднались до "${event.title}"')),
                                    );
                                  },
                                  child: const Text('Приєднатись'),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
}
