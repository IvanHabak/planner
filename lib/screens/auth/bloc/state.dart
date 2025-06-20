part of 'bloc.dart';

class AppState extends Equatable {
  const AppState({
    required this.status,
    this.user = UserModel.empty,
  });

  factory AppState.initial() {
    UserModel currentUser = const UserModel();
    String status = 'unauthenticated';

    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      status = 'authenticated';
      currentUser = UserModel(
        uid: user.uid,
        email: user.email,
        name: user.displayName,
        avatarUrl: user.photoURL,
      );
    }

    return AppState(status: status, user: currentUser);
  }

  final String status;
  final UserModel user;

  @override
  List<Object> get props => [status, user];
}
