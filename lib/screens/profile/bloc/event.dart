import 'package:equatable/equatable.dart';
import '/../models/review.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object> get props => [];
}

// Подія для завантаження відгуків для певного творця подій
class LoadReviewsForCreator extends ReviewEvent {
  final String creatorId;

  const LoadReviewsForCreator(this.creatorId);

  @override
  List<Object> get props => [creatorId];
}

// Подія, що випускається, коли список відгуків оновлюється з репозиторію
class ReviewsUpdated extends ReviewEvent {
  final List<ReviewModel> reviews;

  const ReviewsUpdated(this.reviews);

  @override
  List<Object> get props => [reviews];
}

// Подія для додавання нового відгуку (якщо потрібно буде додати функціонал)
class AddReview extends ReviewEvent {
  final ReviewModel review;

  const AddReview(this.review);

  @override
  List<Object> get props => [review];
}

class ResetReviews extends ReviewEvent {
  const ResetReviews();
}
