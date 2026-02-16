import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_shell_layout.dart';
import '../../core/layout/auth_layout.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/lock_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/appointments/presentation/appointment_form_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/services_catalog/presentation/services_screen.dart';
import '../../features/services_catalog/presentation/service_form_screen.dart';
import '../../features/settings/presentation/profile_edit_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../di/providers.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) => appRouteGuard(ref, state),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthLayout(child: LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const AuthLayout(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const AuthLayout(child: LockScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ClientFormScreen(clientId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ServiceFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ServiceFormScreen(serviceId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AppointmentFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    AppointmentFormScreen(appointmentId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/profile',
            builder: (context, state) => const ProfileEditScreen(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, _) => router.refresh());

  return router;
});
