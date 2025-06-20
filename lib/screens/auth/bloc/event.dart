part of 'bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

class AppLogout extends AppEvent {}

class AppSignUpWithEmail extends AppEvent {
  const AppSignUpWithEmail(
      this.email, this.password, this.name, this.course, this.faculty);

  final String email, password, name;
  final String? faculty;
  final int? course;

  @override
  List<Object> get props => [email, password, name];
}

class AppSignInWithGoogle extends AppEvent {
  const AppSignInWithGoogle({this.name, this.course, this.faculty});
  final String? name;
  final String? faculty;
  final int? course;

  @override
  List<Object> get props => [];
}

class AppSignInWithFacebook extends AppEvent {
  const AppSignInWithFacebook({this.name, this.course, this.faculty});
  final String? name;
  final String? faculty;
  final int? course;

  @override
  List<Object> get props => [];
}

class AppLoginWithEmail extends AppEvent {
  const AppLoginWithEmail(this.email, this.password);

  final String email, password;

  @override
  List<Object> get props => [email, password];
}

class AppUserProfileUpdated extends AppEvent {
  final UserModel user;

  const AppUserProfileUpdated(this.user);

  @override
  List<Object> get props => [user];
}
