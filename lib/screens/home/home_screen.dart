import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/bloc/bloc.dart';
import '../calendar/explore_event.dart';
import '../profile/profile_screen.dart';
import '/screens/calendar/event_calendar.dart';
// import 'events/event_card_list.dart';
// import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const EventListScreen(),
    const EventCalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.blueAccent.shade100,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _currentIndex == 0 ? Colors.white30 : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(Icons.explore, color: Colors.white, size: 20),
              ),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _currentIndex == 1 ? Colors.white30 : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(Icons.calendar_today,
                    color: Colors.white, size: 20),
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _currentIndex == 2 ? Colors.white30 : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
