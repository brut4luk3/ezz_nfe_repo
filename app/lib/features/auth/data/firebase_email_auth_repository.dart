import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Future<void> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _upsertUserDocument(user, isNewUser: true);
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

  Future<void> _upsertUserDocument(User user, {bool isNewUser = false}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final displayName = user.displayName ?? _defaultDisplayName(user.email);

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'appFlavor': _appFlavor,
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
