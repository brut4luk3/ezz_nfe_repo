import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Atalhos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _NavCard(
          title: 'Clientes',
          subtitle: 'Gerencie sua base de clientes',
          icon: Icons.people,
          onTap: () => context.go('/clients'),
        ),
        _NavCard(
          title: 'Produtos',
          subtitle: 'Cadastro de produtos para serviços',
          icon: Icons.inventory_2,
          onTap: () => context.go('/products'),
        ),
        _NavCard(
          title: 'Serviços',
          subtitle: 'Catálogo de serviços',
          icon: Icons.design_services,
          onTap: () => context.go('/services'),
        ),
        _NavCard(
          title: 'Atendimentos',
          subtitle: 'Agendamentos e historico',
          icon: Icons.event,
          onTap: () => context.go('/appointments'),
        ),
        _NavCard(
          title: 'Notas',
          subtitle: 'Status de notas fiscais',
          icon: Icons.receipt_long,
          onTap: () => context.go('/invoices'),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
