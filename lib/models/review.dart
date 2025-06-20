import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel extends Equatable {
  final String id; // Унікальний ID відгуку (з Firestore)
  final String eventId; // ID події, до якої належить відгук
  final String eventName; // Ім'я події (для зручності відображення)
  final String creatorId; // ID творця події (на кого залишають відгук)
  final String reviewerId; // ID користувача, який залишив відгук
  final String reviewerName; // Ім'я користувача, який залишив відгук
  final int rating; // Рейтинг (від 1 до 10)
  final String? comment; // Текст коментаря (може бути null)
  final DateTime date; // Дата залишення відгуку

  const ReviewModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.creatorId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.comment,
    required this.date,
  });

  // Фабричний конструктор для створення ReviewModel з документа Firestore
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      eventId: data['eventId'] as String,
      eventName: data['eventName'] as String,
      creatorId: data['creatorId'] as String,
      reviewerId: data['reviewerId'] as String,
      reviewerName: data['reviewerName'] as String,
      rating: data['rating'] as int,
      comment: data['comment'] as String?,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // Метод для перетворення ReviewModel на Map для збереження у Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'creatorId': creatorId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'date': Timestamp.fromDate(date),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? eventId,
    String? eventName,
    String? creatorId,
    String? reviewerId,
    String? reviewerName,
    int? rating,
    String? comment,
    DateTime? date,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      creatorId: creatorId ?? this.creatorId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        eventName,
        creatorId,
        reviewerId,
        reviewerName,
        rating,
        comment,
        date,
      ];
}
