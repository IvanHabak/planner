part of 'bloc.dart';

enum EventStatus { initial, loading, success, error }

class EventState extends Equatable {
  final EventStatus status;
  final String? errorMessage;
  final List<Event> upcomingEvents;
  final List<Event> userEvents;
  final List<Event> eventsByDate;
  final List<Event> allEvent;

  const EventState({
    this.status = EventStatus.initial,
    this.errorMessage,
    this.upcomingEvents = const [],
    this.userEvents = const [],
    this.eventsByDate = const [],
    this.allEvent = const [],
  });

  EventState copyWith({
    EventStatus? status,
    String? errorMessage,
    List<Event>? upcomingEvents,
    List<Event>? userEvents,
    List<Event>? eventsByDate,
    List<Event>? allEvent,
  }) {
    return EventState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      userEvents: userEvents ?? this.userEvents,
      eventsByDate: eventsByDate ?? this.eventsByDate,
      allEvent: allEvent ?? this.allEvent,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        upcomingEvents,
        userEvents,
        eventsByDate,
        allEvent
      ];
}
