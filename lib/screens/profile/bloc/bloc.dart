import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '/../models/review.dart';
import '/../services/review_repo.dart';
import 'event.dart';
import 'state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final FirebaseFirestore _firestore;

  ReviewBloc(
      {FirebaseFirestore? firestore,
      required ReviewRepository reviewRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const ReviewState.initial()) {
    on<LoadReviewsForCreator>(_onLoadReviewsForCreator);
    on<ResetReviews>(_onResetReviews);
  }

  Future<void> _onLoadReviewsForCreator(
      LoadReviewsForCreator event, Emitter<ReviewState> emit) async {
    emit(state.copyWith(status: ReviewStatus.loading));
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('creatorId', isEqualTo: event.creatorId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      emit(state.copyWith(
        status: ReviewStatus.success,
        reviews: reviews,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReviewStatus.error,
        errorMessage: 'Failed to load reviews: $e',
      ));
    }
  }

  // Обробник для ResetReviews
  void _onResetReviews(ResetReviews event, Emitter<ReviewState> emit) {
    emit(const ReviewState.initial());
  }
}
