import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/config/auth_config.dart';
import 'auth_repository.dart';

class FirebaseEmailAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _appFlavor;

  FirebaseEmailAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String appFlavor,
  })  : _auth = auth,
        _firestore = firestore,
        _appFlavor = appFlavor;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() async {
    try {
      final webClientId = kGoogleWebClientId;
    final googleSignIn = GoogleSignIn(
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final parts = (user.displayName ?? '').trim().split(RegExp(r'\s+'));
        final firstName = parts.isNotEmpty ? parts.first : null;
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
        await _upsertUserDocument(
          user,
          isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
          firstName: firstName,
          lastName: lastName,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthFailure('Nao foi possivel entrar com Google.');
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _upsertUserDocument(user);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthFailure('Nao foi possivel entrar.');
    }
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _upsertUserDocument(
          user,
          isNewUser: true,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthFailure('Nao foi possivel criar a conta.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Usuario nao autenticado.');
    await _upsertUserDocument(
      user,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  Future<void> _upsertUserDocument(
    User user, {
    bool isNewUser = false,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final existing = snapshot.data();

    final first = firstName ?? existing?['firstName'] as String? ?? '';
    final last = lastName ?? existing?['lastName'] as String? ?? '';
    final ph = phone ?? existing?['phone'] as String? ?? '';

    final displayName = _buildDisplayName(
      first.isNotEmpty ? first : null,
      user.displayName,
      user.email,
    );

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'appFlavor': _appFlavor,
      'firstName': first.trim(),
      'lastName': last.trim(),
      'phone': ph.trim(),
    };

    if (!snapshot.exists || isNewUser) {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update(data);
    }
  }

  String _buildDisplayName(String? firstName, String? userDisplayName, String? email) {
    final first = firstName?.trim() ?? '';
    if (first.isNotEmpty) return first;
    return userDisplayName ?? _defaultDisplayName(email);
  }

  String _defaultDisplayName(String? email) {
    if (email == null || !email.contains('@')) return 'Usuario';
    return email.split('@').first;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario nao encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Email ja esta em uso.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email invalido.';
      default:
        return 'Nao foi possivel concluir a operacao.';
    }
  }
}
