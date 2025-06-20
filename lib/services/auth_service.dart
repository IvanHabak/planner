import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  // Метод для входу через Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
      return null;
    } catch (e) {
      print("Помилка під час входу через Google: $e");
      return null;
    }
  }

  // Метод для входу через Facebook
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        return userCredential.user;
      } else {
        print("Помилка під час входу через Facebook: ${result.status}");
        return null;
      }
    } catch (e) {
      print("Помилка під час входу через Facebook: $e");
      return null;
    }
  }

  // Метод для виходу з облікового запису (існуючий)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
    await _auth.signOut();
  }

  // Отримання поточного користувача (існуючий)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Стрім для відстеження змін стану авторизації (існуючий)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
