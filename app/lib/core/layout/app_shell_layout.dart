import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/providers.dart';

class AppShellLayout extends ConsumerWidget {
  final Widget child;

  const AppShellLayout({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/services')) return 2;
    if (location.startsWith('/invoices')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);
    final displayNameAsync = ref.watch(currentUserDisplayNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => context.go('/settings'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      displayNameAsync.maybeWhen(
                        data: (name) => name,
                        orElse: () => 'Usuário',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const Text("Ezz NFe"),
          ],
        ),
        centerTitle: false,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/clients');
              break;
            case 2:
              context.go('/services');
              break;
            case 3:
              context.go('/invoices');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Clients'),
          NavigationDestination(
            icon: Icon(Icons.design_services),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}
