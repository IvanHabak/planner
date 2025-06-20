part of 'bloc.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object> get props => [];
}

class AddEvent extends EventEvent {
  final Event event;
  final File? image;
  final List<File> attachments;

  const AddEvent({
    required this.event,
    this.image,
    this.attachments = const [],
  });

  @override
  List<Object> get props => [event, image ?? '', attachments];
}

class UpdateEvent extends EventEvent {
  final Event event;
  final File? newImage;
  final List<File> newAttachments;
  final bool deleteExistingImage;

  const UpdateEvent({
    required this.event,
    this.newImage,
    this.newAttachments = const [],
    this.deleteExistingImage = false,
  });

  @override
  List<Object> get props =>
      [event, newImage ?? '', newAttachments, deleteExistingImage];
}

class DeleteEvent extends EventEvent {
  final String eventId;

  const DeleteEvent(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class ToggleEventPublicStatus extends EventEvent {
  final String eventId;
  final bool isPublic;

  const ToggleEventPublicStatus(
      {required this.eventId, required this.isPublic});

  @override
  List<Object> get props => [eventId, isPublic];
}

class JoinEvent extends EventEvent {
  final String eventId;
  final String userId;

  const JoinEvent({required this.eventId, required this.userId});

  @override
  List<Object> get props => [eventId, userId];
}

class LeaveEvent extends EventEvent {
  final String eventId;
  final String userId;

  const LeaveEvent({required this.eventId, required this.userId});

  @override
  List<Object> get props => [eventId, userId];
}

// Події для стрімів даних
class LoadUpcomingEvents extends EventEvent {}

class LoadUserEvents extends EventEvent {
  final String userId;
  const LoadUserEvents(this.userId);
  @override
  List<Object> get props => [userId];
}

class LoadEventsByDate extends EventEvent {
  final String userId;
  final DateTime date;
  const LoadEventsByDate({required this.userId, required this.date});
  @override
  List<Object> get props => [userId, date];
}

class LoadEventsForCreator extends EventEvent {
  final String creatorId;

  const LoadEventsForCreator(this.creatorId);

  @override
  List<Object> get props => [creatorId];
}

// Додана подія для скидання стану EventBloc
class ResetEvents extends EventEvent {
  const ResetEvents();
}
