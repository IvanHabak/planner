import 'dart:async'; // Додано для StreamSubscription

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart'; // Для debugPrint
import 'package:student_planner/screens/auth/bloc/failure.dart';
import 'package:student_planner/services/auth_service.dart';
import '/models/user.dart';

part 'event.dart';
part 'state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  // Зміни в конструкторі для ініціалізації
  AppBloc({AuthService? authService}) // Додано параметр authService
      : _authService =
            authService ?? AuthService(), // Ініціалізація _authService
        super(AppState.initial()) {
    on<AppSignUpWithEmail>(signUpWithEmail);
    on<AppSignInWithGoogle>(signInWithGoogle);
    on<AppSignInWithFacebook>(signInWithFacebook);
    on<AppLoginWithEmail>(logInWithEmailAndPassword);
    on<AppLogout>(logOut);
    on<AppUserProfileUpdated>(
        onAppUserProfileUpdated); // Назва методу для обробника
    _userSubscription =
        _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        // Користувач залогінений, завантажуємо повні дані з Firestore
        try {
          final userModel = await _loadUserData(firebaseUser.uid);
          // Оновлюємо стан Bloc з актуальними даними користувача
          emit(AppState(status: 'authenticated', user: userModel));
        } catch (e) {
          debugPrint('AppBloc: Error loading user data after auth change: $e');
          // Якщо помилка при завантаженні даних, можливо, користувач "частково" автентифікований
          // або є проблеми з доступом до Firestore. Встановлюємо порожній стан.
          emit(
              const AppState(status: 'unauthenticated', user: UserModel.empty));
        }
      } else {
        // Користувач не залогінений
        emit(const AppState(status: 'unauthenticated', user: UserModel.empty));
      }
    });
    // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---
  }

  StreamSubscription<firebase_auth.User?>? _userSubscription;

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Додаємо поле AuthService
  final AuthService _authService;

  Future<void> signUpWithEmail(
      AppSignUpWithEmail event, Emitter<AppState> emit) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        // Отримання UserCredential
        email: event.email,
        password: event.password,
      );
      final uid = userCredential.user?.uid; // Отримання UID

      if (uid == null) {
        debugPrint('AppBloc: User UID is null after signup.');
        // Тут краще емітувати стан помилки, але за вашим запитом - просто return
        return;
      }

      // Створюємо UserModel з даними реєстрації
      UserModel newUser = UserModel(
        uid: uid,
        email: userCredential.user?.email,
        name: userCredential.user?.displayName,
        avatarUrl: userCredential.user?.photoURL,
        course: event.course, // Передаємо дані з події
        faculty: event.faculty, // Передаємо дані з події
      );
      await _saveUserData(newUser); // Зберігаємо дані в Firestore

      // Після успішної реєстрації, _userSubscription автоматично оновить стан Bloc.
      // Цей emit може бути проміжним.
      emit(AppState(status: 'authenticated', user: newUser));
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AppBloc: FirebaseAuthException during signup: ${e.code} - ${e.message}');
      throw SignUpWithEmailAndPasswordFailure.fromCode(
          e.code); // Повертаємо оригінальну логіку помилок
    } catch (e) {
      // Змінено на 'e' для виведення повідомлення
      debugPrint('AppBloc: Unknown error during signup: $e');
      throw const SignUpWithEmailAndPasswordFailure(); // Повертаємо оригінальну логіку помилок
    }
  }

  Future<void> signInWithGoogle(
      AppSignInWithGoogle event, Emitter<AppState> emit) async {
    try {
      firebase_auth.User? user =
          await _authService.signInWithGoogle(); // Використовуємо _authService

      if (user == null) {
        debugPrint('AppBloc: Google Sign-In failed or was cancelled.');
        return;
      }

      // --- МІНІМАЛЬНІ ЗМІНИ: Завантажуємо повні дані користувача з Firestore ---
      final userModel = await _loadUserData(user.uid,
          initialCourse: event.course, initialFaculty: event.faculty);
      // _userSubscription також оновить стан, але цей emit гарантує негайне оновлення.
      emit(AppState(status: 'authenticated', user: userModel));
      // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AppBloc: FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      // Змінено на 'e' для виведення повідомлення
      debugPrint('AppBloc: Unknown error during Google sign-in: $e');
      rethrow;
    }
  }

  Future<void> signInWithFacebook(
      AppSignInWithFacebook event, Emitter<AppState> emit) async {
    try {
      firebase_auth.User? user = await _authService
          .signInWithFacebook(); // Використовуємо _authService

      if (user == null) {
        debugPrint('AppBloc: Facebook Sign-In failed or was cancelled.');
        return;
      }

      // --- МІНІМАЛЬНІ ЗМІНИ: Завантажуємо повні дані користувача з Firestore ---
      final userModel = await _loadUserData(user.uid,
          initialCourse: event.course, initialFaculty: event.faculty);
      emit(AppState(status: 'authenticated', user: userModel));
      // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AppBloc: FirebaseAuthException during Facebook sign-in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      // Змінено на 'e' для виведення повідомлення
      debugPrint('AppBloc: Unknown error during Facebook sign-in: $e');
      rethrow;
    }
  }

  Future<void> logInWithEmailAndPassword(
      AppLoginWithEmail event, Emitter<AppState> emit) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        // Отримання UserCredential
        email: event.email,
        password: event.password,
      );
      final uid = userCredential.user?.uid; // Отримання UID

      if (uid == null) {
        debugPrint('AppBloc: User UID is null after login.');
        // Тут краще емітувати стан помилки, але за вашим запитом - просто return
        return;
      }

      // --- МІНІМАЛЬНІ ЗМІНИ: Завантажуємо повні дані користувача з Firestore ---
      final userModel = await _loadUserData(uid);
      emit(AppState(status: 'authenticated', user: userModel));
      // Приберіть цей рядок, він дублює попередній emit
      // emit(const AppState(status: 'authenticated'));
      // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AppBloc: FirebaseAuthException during login: ${e.code} - ${e.message}');
      throw LogInWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (e) {
      // Змінено на 'e' для виведення повідомлення
      debugPrint('AppBloc: Unknown error during login: $e');
      throw const LogInWithEmailAndPasswordFailure();
    }
  }

  Future<void> logOut(AppLogout event, Emitter<AppState> emit) async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
      ]);
      // _userSubscription вже обробить зміну на 'unauthenticated'
      // emit(const AppState(status: 'unauthenticated', user: UserModel())); // Цей рядок може бути надлишковим
    } catch (e) {
      // Змінено на 'e' для виведення повідомлення
      debugPrint('AppBloc: Error during logout: $e');
      // throw LogOutFailure(); // Залишаємо вашу оригінальну логіку
    }
  }

  // --- МІНІМАЛЬНІ ЗМІНИ: _loadUserData тепер повертає UserModel ---
  Future<UserModel> _loadUserData(String uid,
      {int? initialCourse, String? initialFaculty}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        debugPrint('AppBloc: User data loaded from Firestore for UID: $uid');
        return UserModel.fromFirestore(doc);
      } else {
        debugPrint(
            'AppBloc: User data not found in Firestore for UID: $uid. Creating new entry.');
        // Створюємо новий документ користувача, якщо його немає
        final firebase_auth.User? currentUser = _firebaseAuth.currentUser;
        UserModel newUserModel = UserModel(
          uid: uid,
          name: currentUser?.displayName ?? '',
          email: currentUser?.email ?? '',
          avatarUrl: currentUser?.photoURL,
          course: initialCourse, // Використовуємо надані початкові дані
          faculty: initialFaculty, // Використовуємо надані початкові дані
        );
        await _saveUserData(
            newUserModel); // Зберігаємо новоствореного користувача
        return newUserModel;
      }
    } catch (e) {
      debugPrint('AppBloc: Error loading user data from Firestore: $e');
      rethrow; // Перекидаємо помилку далі
    }
  }
  // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---

  // --- МІНІМАЛЬНІ ЗМІНИ: _saveUserData з merge:true ---
  Future<void> _saveUserData(UserModel userModel) async {
    if (userModel.uid == null || userModel.uid!.isEmpty) {
      debugPrint(
          'AppBloc: Attempted to save user data with null or empty UID. Aborting.');
      return;
    }
    try {
      debugPrint(
          'AppBloc: Saving user data to Firestore for UID: ${userModel.uid}');
      await _firestore.collection('users').doc(userModel.uid).set(
          userModel.toMap(),
          SetOptions(merge: true)); // Забезпечено merge: true
      debugPrint('AppBloc: User data saved successfully.');
    } catch (e) {
      debugPrint('AppBloc: Error saving user data to Firestore: $e');
      rethrow;
    }
  }
  // --- КІНЕЦЬ МІНІМАЛЬНИХ ЗМІН ---

  // Обробник для оновлення профілю користувача
  Future<void> onAppUserProfileUpdated(
      AppUserProfileUpdated event, Emitter<AppState> emit) async {
    try {
      await _saveUserData(event.user);
      emit(AppState(
          status: 'authenticated',
          user: event.user)); // Оновлюємо стан з новим UserModel
    } catch (e) {
      debugPrint('AppBloc: Error in onAppUserProfileUpdated: $e');
      // Якщо ви не хочете статусів, ви можете тут просто ігнорувати помилку,
      // або log'увати її. Але це не рекомендується.
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel(); // Відміна підписки при закритті Bloc
    return super.close();
  }
}
