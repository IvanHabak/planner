// lib/features/events/presentation/event_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/event_repo.dart';
import '../../models/event.dart';
import 'event_card.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventRepo = Provider.of<EventRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
      ),
      body: StreamBuilder<List<Event>>(
        stream: eventRepo.getUpcomingEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text('No upcoming events'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/event_details',
                  arguments: event.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
