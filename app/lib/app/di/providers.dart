import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/biometric_service.dart';
import '../../core/services/secure_kv_service.dart';
import '../theme/theme_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_email_auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/appointments/data/appointments_repository.dart';
import '../../features/clients/data/clients_repository.dart';
import '../../features/invoices/data/invoices_repository.dart';
import '../../features/services_catalog/data/services_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final appFlavorProvider = Provider<String>((ref) {
  return const String.fromEnvironment('FLAVOR', defaultValue: 'dev');
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final secureKvServiceProvider = Provider<SecureKvService>((ref) {
  return SecureKvService();
});

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(secureKvServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseEmailAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    appFlavor: ref.watch(appFlavorProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    biometricService: ref.watch(biometricServiceProvider),
    secureKvService: ref.watch(secureKvServiceProvider),
  );
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.uid;
});

final clientsRepositoryProvider = Provider<ClientsRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ClientsRepository(
    firestore: ref.watch(firestoreProvider),
    uid: uid,
  );
});

final servicesRepositoryProvider = Provider<ServicesRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ServicesRepository(
    firestore: ref.watch(firestoreProvider),
    uid: uid,
  );
});

final appointmentsRepositoryProvider = Provider<AppointmentsRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return AppointmentsRepository(
    firestore: ref.watch(firestoreProvider),
    uid: uid,
  );
});

final invoicesRepositoryProvider = Provider<InvoicesRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return InvoicesRepository(
    firestore: ref.watch(firestoreProvider),
    uid: uid,
  );
});
