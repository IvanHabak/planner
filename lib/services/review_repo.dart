import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/review.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Метод для отримання відгуків, залишених для певного творця подій (вашого користувача)
  Stream<List<ReviewModel>> getReviewsForCreator(String creatorId) {
    debugPrint('ReviewRepository: Fetching reviews for creatorId: $creatorId');
    return _firestore
        .collection('reviews')
        .where('creatorId',
            isEqualTo: creatorId) // Фільтруємо за creatorId події
        .orderBy('date', descending: true) // Сортуємо за датою
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs.map((doc) {
        debugPrint(
            'ReviewRepository: Fetched review: ${doc.id} -> ${doc.data()}');
        return ReviewModel.fromFirestore(doc);
      }).toList();
      debugPrint(
          'ReviewRepository: Total reviews fetched for creator $creatorId: ${reviews.length}');
      return reviews;
    }).handleError((error) {
      debugPrint(
          'ReviewRepository: Error fetching reviews for creator $creatorId: $error');
      return <ReviewModel>[];
    });
  }

  // Метод для додавання нового відгуку
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').add(review.toFirestore());
      debugPrint('ReviewRepository: Review added successfully!');
    } catch (e) {
      debugPrint('ReviewRepository: Error adding review: $e');
      rethrow;
    }
  }
}
