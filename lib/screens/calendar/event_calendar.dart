import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_planner/screens/auth/bloc/bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '/services/event_repo.dart';
import '/models/event.dart';
import './event_card.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  _EventCalendarScreenState createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Event> events = [];
  CalendarFormat calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Calendar')),
      body: StreamBuilder<List<Event>>(
          stream:
              Provider.of<EventRepository>(context).getUserEvents(user.uid!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            events = snapshot.data ?? [];

            List<Event> getEventByDate(DateTime day) {
              List<Event> e = events
                  .where((event) =>
                      event.dateTime.isAfter(day) &&
                      event.dateTime.isBefore(day.add(
                        Duration(days: 1),
                      )))
                  .toList();

              return e;
            }

            return Column(children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _selectedDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(90),
                      borderRadius: BorderRadius.circular(6)),
                  selectedDecoration: BoxDecoration(
                      color: Colors.blueAccent.shade100,
                      borderRadius: BorderRadius.circular(6)),
                ),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  }
                },
                calendarFormat: calendarFormat,
                onFormatChanged: (format) {
                  final newFormat = calendarFormat == CalendarFormat.week
                      ? CalendarFormat.month
                      : CalendarFormat.week;

                  setState(() {
                    calendarFormat = newFormat;
                  });
                },
                eventLoader: (day) => getEventByDate(day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      showJoinButton: false,
                    );
                  },
                ),
              ),
            ]);
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_event'),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14.0), // Радіус заокруглення кутів
        ),
      ),
    );
  }
}
