import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/secure_kv_service.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool biometricEnabled;
  final bool biometricUnlocked;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.biometricEnabled = false,
    this.biometricUnlocked = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool? biometricEnabled,
    bool? biometricUnlocked,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricUnlocked: biometricUnlocked ?? this.biometricUnlocked,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final BiometricService _biometricService;
  final SecureKvService _secureKvService;
  final Future<void> Function()? _onLogout;
  StreamSubscription<User?>? _authSub;

  AuthController({
    required AuthRepository authRepository,
    required BiometricService biometricService,
    required SecureKvService secureKvService,
    Future<void> Function()? onLogout,
  })  : _authRepository = authRepository,
        _biometricService = biometricService,
        _secureKvService = secureKvService,
        _onLogout = onLogout,
        super(const AuthState()) {
    _authSub = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = const AuthState(
        user: null,
        status: AuthStatus.unauthenticated,
        biometricEnabled: false,
        biometricUnlocked: false,
      );
      return;
    }

    final enabled = await _secureKvService.getBool(_biometricKey(user.uid));
    state = state.copyWith(
      user: user,
      status: AuthStatus.authenticated,
      biometricEnabled: enabled ?? false,
      biometricUnlocked: false,
      errorMessage: null,
    );
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signInWithGoogle();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signInWithEmail(email, password);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> register(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.registerWithEmail(
        email,
        password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _onLogout?.call();
    if (!mounted) return;
    state = state.copyWith(
      biometricUnlocked: false,
      biometricEnabled: false,
      errorMessage: null,
    );
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: null);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<bool> unlockWithBiometrics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final canCheck = await _biometricService.canCheckBiometrics();
    if (!canCheck) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Biometria indisponivel no dispositivo.',
      );
      return false;
    }

    final ok = await _biometricService.authenticate(
      reason: 'Desbloquear acesso',
    );
    if (!mounted) return false;
    state = state.copyWith(
      isLoading: false,
      biometricUnlocked: ok,
      errorMessage: ok ? null : 'Falha ou cancelado.',
    );
    return ok;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final user = state.user;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Usuario nao autenticado.');
      return;
    }

    if (!enabled) {
      await _secureKvService.setBool(_biometricKey(user.uid), false);
      state = state.copyWith(
        biometricEnabled: false,
        biometricUnlocked: false,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final canCheck = await _biometricService.canCheckBiometrics();
    if (!canCheck) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Biometria indisponivel no dispositivo.',
      );
      return;
    }

    final ok = await _biometricService.authenticate(
      reason: 'Confirmar biometria para habilitar',
    );
    if (!mounted) return;

    if (!ok) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Falha ou cancelado.',
      );
      return;
    }

    await _secureKvService.setBool(_biometricKey(user.uid), true);
    state = state.copyWith(
      isLoading: false,
      biometricEnabled: true,
      biometricUnlocked: true,
      errorMessage: null,
    );
  }

  String _biometricKey(String uid) => 'biometricEnabled:$uid';
}
