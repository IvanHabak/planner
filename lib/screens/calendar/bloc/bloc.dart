import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Додано для debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '/models/event.dart';
import '/services/event_repo.dart';

part 'event.dart';
part 'state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository _eventRepository;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // RxDart BehaviorSubject для стрімів даних
  // Ці контролери будуть утримувати актуальні дані, отримані від репозиторію.
  final _upcomingEventsController = BehaviorSubject<List<Event>>();
  final _userEventsController = BehaviorSubject<List<Event>>();
  final _eventsByDateController = BehaviorSubject<List<Event>>();
  // Додаємо контролер для всіх подій користувача, які ми будемо рахувати
  final _allUserEventsController = BehaviorSubject<List<Event>>();

  EventBloc({
    required EventRepository eventRepository,
    required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  })  : _eventRepository = eventRepository,
        _flutterLocalNotificationsPlugin = flutterLocalNotificationsPlugin,
        super(const EventState()) {
    tz.initializeTimeZones();

    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<ToggleEventPublicStatus>(_onToggleEventPublicStatus);
    on<JoinEvent>(_onJoinEvent);
    on<LeaveEvent>(_onLeaveEvent);
    // Обробник для завантаження ВСІХ подій користувача (для підрахунку)
    on<LoadEventsForCreator>((event, emit) async {
      emit(state.copyWith(status: EventStatus.loading));
      try {
        _eventRepository.getAllUserEvents(event.creatorId).listen((events) {
          _allUserEventsController.add(events);
          debugPrint(
              'EventBloc: Loaded ${events.length} events for creator ${event.creatorId}');
        }, onError: (e) {
          emit(state.copyWith(
              status: EventStatus.error,
              errorMessage: 'Failed to load all user events for creator: $e'));
          debugPrint('EventBloc: Error loading all user events: $e');
        });

        emit(state.copyWith(
            status: EventStatus
                .success)); // Встановлюємо статус loaded після запуску listen
      } catch (e) {
        emit(state.copyWith(
            status: EventStatus.error,
            errorMessage: 'Failed to initiate loading of all user events: $e'));
      }
    });

    on<LoadUpcomingEvents>((event, emit) {
      _eventRepository.getUpcomingEvents().listen((events) {
        _upcomingEventsController.add(events);
      }, onError: (e) {
        emit(state.copyWith(
            status: EventStatus.error,
            errorMessage: 'Failed to load upcoming events: $e'));
      });
    });

    on<LoadUserEvents>((event, emit) {
      _eventRepository.getUserEvents(event.userId).listen((events) {
        _userEventsController.add(events);
      }, onError: (e) {
        emit(state.copyWith(
            status: EventStatus.error,
            errorMessage: 'Failed to load user events: $e'));
      });
    });

    on<LoadEventsByDate>((event, emit) {
      _eventRepository.getEventsByDate(event.userId, event.date).listen(
          (events) {
        _eventsByDateController.add(events);
      }, onError: (e) {
        emit(state.copyWith(
            status: EventStatus.error,
            errorMessage: 'Failed to load events by date: $e'));
      });
    });

    // Новий обробник для скидання стану подій (EventBloc)
    on<ResetEvents>((event, emit) {
      _allUserEventsController.add([]); // Очищуємо кешовані дані
      _upcomingEventsController.add([]);
      _userEventsController.add([]);
      _eventsByDateController.add([]);
      debugPrint('EventBloc: Events state reset.');
    });
  }

  // Метод для отримання потоку всіх подій користувача для UI
  Stream<List<Event>> get allUserEvents => _allUserEventsController.stream;
  Stream<List<Event>> get upcomingEvents => _upcomingEventsController.stream;
  Stream<List<Event>> get userEvents => _userEventsController.stream;
  Stream<List<Event>> get eventsByDate => _eventsByDateController.stream;

  // --- КІНЕЦЬ НОВИХ/ЗМІНЕНИХ МЕТОДІВ ---

  Future<void> _onAddEvent(AddEvent event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      final newDocRef = _eventRepository.getNewEventDocRef();
      final newEventWithId = event.event.copyWith(id: newDocRef.id);

      await _eventRepository.createEvent(
        event: newEventWithId,
        image: event.image,
        attachments: event.attachments,
      );

      _scheduleNotifications(newEventWithId);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error, errorMessage: 'Failed to add event: $e'));
    }
  }

  Future<void> _onUpdateEvent(
      UpdateEvent event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      await _eventRepository.updateEvent(
        event: event.event,
        newImage: event.newImage,
        newAttachments: event.newAttachments,
        deleteExistingImage: event.deleteExistingImage,
      );
      _cancelNotifications(event.event.id!); // ID може бути null, додайте !
      _scheduleNotifications(event.event);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error,
          errorMessage: 'Failed to update event: $e'));
    }
  }

  Future<void> _onDeleteEvent(
      DeleteEvent event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      await _eventRepository.deleteEvent(event.eventId);
      _cancelNotifications(event.eventId);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error,
          errorMessage: 'Failed to delete event: $e'));
    }
  }

  Future<void> _onToggleEventPublicStatus(
      ToggleEventPublicStatus event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      await _eventRepository.changePublic(event.eventId, event.isPublic);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error,
          errorMessage: 'Failed to change event public status: $e'));
    }
  }

  Future<void> _onJoinEvent(JoinEvent event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      await _eventRepository.joinEvent(event.eventId, event.userId);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error, errorMessage: 'Failed to join event: $e'));
    }
  }

  Future<void> _onLeaveEvent(LeaveEvent event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    try {
      await _eventRepository.leaveEvent(event.eventId, event.userId);
      emit(state.copyWith(status: EventStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: EventStatus.error,
          errorMessage: 'Failed to leave event: $e'));
    }
  }

  void _scheduleNotifications(Event event) {
    if (event.id == null || event.id!.isEmpty) {
      debugPrint('Cannot schedule notifications for event with empty ID.');
      return;
    }

    final eventTime = event.dateTime;
    final int eventIdHash = event.id.hashCode;

    final String eventIdPayload = event.id!;

    final oneDayBefore = eventTime.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      _flutterLocalNotificationsPlugin.zonedSchedule(
        eventIdHash + 1,
        'Нагадування про подію: ${event.title}',
        'Подія "${event.title}" відбудеться завтра, ${oneDayBefore.day}.${oneDayBefore.month} о ${oneDayBefore.hour}:${oneDayBefore.minute}.',
        tz.TZDateTime.from(oneDayBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Нагадування про події',
            channelDescription: 'Нагадування про заплановані події',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: eventIdPayload,
      );
    }

    final thirtyMinutesBefore = eventTime.subtract(const Duration(minutes: 30));
    if (thirtyMinutesBefore.isAfter(DateTime.now())) {
      _flutterLocalNotificationsPlugin.zonedSchedule(
        eventIdHash + 2,
        'Нагадування про подію: ${event.title}',
        'Подія "${event.title}" почнеться через 30 хвилин.',
        tz.TZDateTime.from(thirtyMinutesBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Нагадування про події',
            channelDescription: 'Нагадування про заплановані події',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: eventIdPayload,
      );
    }

    if (eventTime.isAfter(DateTime.now())) {
      _flutterLocalNotificationsPlugin.zonedSchedule(
        eventIdHash + 3,
        'Подія розпочинається: ${event.title}',
        'Подія "${event.title}" вже розпочалась!',
        tz.TZDateTime.from(eventTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Нагадування про події',
            channelDescription: 'Нагадування про заплановані події',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: eventIdPayload,
      );
    }
  }

  void _cancelNotifications(String eventId) {
    final int eventIdHash = eventId.hashCode;
    _flutterLocalNotificationsPlugin.cancel(eventIdHash + 1);
    _flutterLocalNotificationsPlugin.cancel(eventIdHash + 2);
    _flutterLocalNotificationsPlugin.cancel(eventIdHash + 3);
  }

  @override
  Future<void> close() {
    _upcomingEventsController.close();
    _userEventsController.close();
    _eventsByDateController.close();
    _allUserEventsController.close(); // Закриваємо новий контролер
    return super.close();
  }
}
