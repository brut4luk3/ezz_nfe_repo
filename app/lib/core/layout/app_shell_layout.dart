import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellLayout extends StatelessWidget {
  final Widget child;

  const AppShellLayout({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/services')) return 2;
    if (location.startsWith('/invoices')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ezz NFe"),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
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
