import 'package:equatable/equatable.dart';
import '/../models/review.dart';

enum ReviewStatus { initial, loading, success, error }

class ReviewState extends Equatable {
  final List<ReviewModel> reviews;
  final ReviewStatus status;
  final String? errorMessage;

  const ReviewState({
    this.reviews = const [],
    this.status = ReviewStatus.initial,
    this.errorMessage,
  });

  const ReviewState.initial()
      : this(
            status: ReviewStatus.initial,
            reviews: const [],
            errorMessage: null);

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    ReviewStatus? status,
    String? errorMessage,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [reviews, status, errorMessage];
}
