// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart'; // Provider більше не потрібен
import 'package:student_planner/screens/auth/bloc/bloc.dart';
import 'package:student_planner/screens/profile/bloc/bloc.dart';
import 'package:student_planner/screens/profile/bloc/event.dart';
import 'package:student_planner/screens/profile/bloc/state.dart';

import '../../models/event.dart';
import '../../models/review.dart';
import '../calendar/bloc/bloc.dart';
import 'edite_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Зберігаємо uid поточного користувача, щоб відстежувати зміни
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ініціалізуємо _currentUserId при першому завантаженні
      _currentUserId = context.read<AppBloc>().state.user.uid;
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final currentUserState = context.read<AppBloc>().state;
    final userModel = currentUserState.user;

    // Перевірка на null для uid, перш ніж викликати isNotEmpty
    if (userModel.uid != null && userModel.uid!.isNotEmpty) {
      // Завантажуємо відгуки тільки якщо uid змінився або це перше завантаження
      if (userModel.uid != _currentUserId) {
        _currentUserId = userModel.uid; // Оновлюємо збережений uid
        context.read<ReviewBloc>().add(LoadReviewsForCreator(userModel.uid!));
        context.read<EventBloc>().add(LoadEventsForCreator(userModel.uid!));
      } else if (_currentUserId != null &&
          _currentUserId!.isNotEmpty &&
          context.read<ReviewBloc>().state.status == ReviewStatus.initial) {
        // Завантажуємо, якщо uid не змінився, але ReviewBloc ще в початковому стані
        context.read<ReviewBloc>().add(LoadReviewsForCreator(userModel.uid!));
        context.read<EventBloc>().add(LoadEventsForCreator(userModel.uid!));
      }
    } else {
      // Якщо користувач не автентифікований або uid порожній, очищаємо відгуки
      context
          .read<ReviewBloc>()
          .add(ResetReviews()); // Подія для очищення стану ReviewBloc
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listener: (context, appState) {
        if (appState.status == 'authenticated' ||
            appState.status == 'unauthenticated') {
          _loadProfileData(); // Перезавантажуємо дані (включаючи відгуки)
        }
      },
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          final userModel = appState.user;

          if (userModel.uid == null || userModel.uid!.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // context.read<EventBloc>().add(LoadEventsForCreator(userModel.uid!));
          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 170.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          child: (userModel.name != null &&
                                  userModel.name!.isNotEmpty)
                              ? Text(
                                  userModel.name![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black54),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const ProfileEditPage()),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.black54),
                      onPressed: () {
                        context.read<AppBloc>().add(AppLogout());
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          userModel.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${userModel.faculty ?? 'Faculty Not Specified'}, ${userModel.course != null ? '${userModel.course.toString()} Course' : 'Course Not Specified'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<ReviewBloc, ReviewState>(
                          builder: (context, reviewState) {
                            if (reviewState.status == ReviewStatus.loading) {
                              return const CircularProgressIndicator();
                            } else if (reviewState.status ==
                                ReviewStatus.error) {
                              return Text(
                                  'Error loading reviews: ${reviewState.errorMessage}');
                            } else {
                              final int reviewsCount =
                                  reviewState.reviews.length;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 0),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.shade100,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoColumn(
                                      icon: Icons.rate_review,
                                      label: 'Reviews',
                                      value: reviewsCount.toString(),
                                    ),
                                    StreamBuilder<List<Event>>(
                                      stream: context
                                          .read<EventBloc>()
                                          .allUserEvents,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            snapshot.data == null) {
                                          return _buildInfoColumn(
                                            icon: Icons.event,
                                            label: 'Events Created',
                                            value:
                                                '...', // Індикатор завантаження
                                          );
                                        } else if (snapshot.hasError) {
                                          return _buildInfoColumn(
                                            icon: Icons.event,
                                            label: 'Events Created',
                                            value: 'Error',
                                          );
                                        } else {
                                          final int eventsCount =
                                              snapshot.data!.length;
                                          return _buildInfoColumn(
                                            icon: Icons.event,
                                            label: 'Events Created',
                                            value: eventsCount.toString(),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Center(
                            child: Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Блок для відображення списку відгуків
                        BlocBuilder<ReviewBloc, ReviewState>(
                          builder: (context, reviewState) {
                            if (reviewState.status == ReviewStatus.loading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (reviewState.status ==
                                ReviewStatus.error) {
                              return Center(
                                  child: Text(
                                      'Error: ${reviewState.errorMessage}'));
                            } else if (reviewState.reviews.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20.0),
                                child: ReviewCard(
                                    review: ReviewModel(
                                  id: '1',
                                  eventId: '1',
                                  eventName: 'Meet',
                                  creatorId: 'oUiu31Fc8EcJ8DtDKIkKWl08eRA2',
                                  reviewerId: 'oUiu31Fc8EcJ8DtDKIkKWl08eRA2',
                                  reviewerName: 'Samanta',
                                  rating: 8,
                                  date: DateTime.now(),
                                )),
                                // Text(
                                //   'No reviews for your events yet.',
                                //   style: TextStyle(
                                //       fontSize: 16, color: Colors.grey[600]),
                                // ),
                              );
                            } else {
                              return Column(
                                children: reviewState.reviews
                                    .map((review) => ReviewCard(review: review))
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white30,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 14),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ]);
  }
}

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int visualRatingOutOf5 = (review.rating / 2).round();
    final int fullStars = visualRatingOutOf5;
    final bool hasHalfStar = (review.rating % 2 != 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(fullStars, (index) {
                            return const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                          if (hasHalfStar)
                            const Icon(
                              Icons.star_half,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ...List.generate(
                              5 - fullStars - (hasHalfStar ? 1 : 0), (index) {
                            return const Icon(
                              Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '(${review.rating}/10)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${review.date.day.toString().padLeft(2, '0')}-${review.date.month.toString().padLeft(2, '0')}-${review.date.year.toString().substring(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  review.comment!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Event: ${review.eventName}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
