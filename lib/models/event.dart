import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_type.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? location;
  final String creatorId;
  final List<String> participants;
  final EventType type;
  final String? imageUrl;
  final List<String> attachments;
  final bool isPublic;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
    required this.creatorId,
    this.participants = const [],
    required this.type,
    this.imageUrl,
    this.attachments = const [],
    this.isPublic = false,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      creatorId: data['creatorId'] ?? '',
      imageUrl: data['imageUrl'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      type: EventType.values[data['type'] ?? 0],
      location: data['location'],
      participants: List<String>.from(data['participants'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      isPublic: data['isPublic'] ?? false,
    );
  }

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'],
      description: map['description'],
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      location: map['location'],
      creatorId: map['creatorId'],
      participants: List<String>.from(map['participants'] ?? []),
      type: EventType.values[map['type'] ?? 0],
      imageUrl: map['imageUrl'],
      attachments: List<String>.from(map['attachments'] ?? []),
      isPublic: map['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'creatorId': creatorId,
      'participants': participants,
      'type': type.index,
      'imageUrl': imageUrl,
      'attachments': attachments,
      'isPublic': isPublic,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? creatorId,
    List<String>? participants,
    EventType? type,
    String? imageUrl,
    List<String>? attachments,
    bool? isPublic,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
