import 'package:flutter/material.dart';

enum EventType {
  lecture, // Лекція
  workshop, // Майстер-клас
  party, // Вечірка
  meeting, // Зустріч
  exam, // Екзамен
  sport, // Спортивна подія
  other // Інше
}

// Допоміжні методи для роботи з EventType
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.lecture:
        return 'Lecture';
      case EventType.workshop:
        return 'Workshop';
      case EventType.party:
        return 'Party';
      case EventType.meeting:
        return 'Meeting';
      case EventType.exam:
        return 'Exam';
      case EventType.sport:
        return 'Sport Event';
      case EventType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.lecture:
        return Icons.school;
      case EventType.workshop:
        return Icons.work;
      case EventType.party:
        return Icons.celebration;
      case EventType.meeting:
        return Icons.people;
      case EventType.exam:
        return Icons.assignment;
      case EventType.sport:
        return Icons.sports;
      case EventType.other:
        return Icons.event;
    }
  }

  Color get color {
    switch (this) {
      case EventType.lecture:
        return Colors.blue;
      case EventType.workshop:
        return Colors.green;
      case EventType.party:
        return Colors.purple;
      case EventType.meeting:
        return Colors.orange;
      case EventType.exam:
        return Colors.red;
      case EventType.sport:
        return Colors.teal;
      case EventType.other:
        return Colors.grey;
    }
  }
}
