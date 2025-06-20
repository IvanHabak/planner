import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String? name;
  final String? email;
  final String? faculty;
  final int? course;
  final String? avatarUrl;

  const UserModel({
    this.uid,
    this.name,
    this.email,
    this.faculty,
    this.course,
    this.avatarUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      faculty: data['faculty'],
      course: data['course'],
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'faculty': faculty,
      'course': course,
      'avatarUrl': avatarUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? avatarUrl,
    int? course,
    String? faculty,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      course: course ?? this.course,
      faculty: faculty ?? this.faculty,
    );
  }

  static const empty = UserModel();

  bool get isEmpty => this == UserModel.empty;

  @override
  List<Object?> get props => [uid, email, name, faculty, course, avatarUrl];
}
