import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';

String? appRouteGuard(Ref ref, GoRouterState state) {
  final authState = ref.watch(authControllerProvider);

  final location = state.matchedLocation;
  final isLogin = location == '/login';
  final isRegister = location == '/register';
  final isLock = location == '/lock';

  if (authState.user == null) {
    return (isLogin || isRegister) ? null : '/login';
  }

  if (authState.biometricEnabled && !authState.biometricUnlocked) {
    return isLock ? null : '/lock';
  }

  if (authState.user != null && (isLogin || isRegister || isLock)) {
    return '/home';
  }

  return null;
}
