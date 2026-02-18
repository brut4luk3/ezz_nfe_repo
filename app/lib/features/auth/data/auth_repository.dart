import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phone,
  });
  Future<void> signOut();
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
  });
}
