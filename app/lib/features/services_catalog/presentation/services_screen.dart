import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../data/service_item_model.dart';
import 'services_providers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);
    final actionState = ref.watch(servicesControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/services/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar servico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            if (actionState.errorMessage != null)
              Text(
                actionState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: servicesAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (items) {
                  final filtered = _filterServices(items, _query);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum servico encontrado.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final service = filtered[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            '${formatCurrency(service.priceCents)}'
                            '${service.durationMinutes != null ? ' • ${service.durationMinutes} min' : ''}',
                          ),
                          onTap: () => context.go('/services/${service.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showConfirmDialog(
                                context: context,
                                title: 'Remover servico',
                                message:
                                    'Tem certeza que deseja remover este servico?',
                              );
                              if (!ok) return;
                              await ref
                                  .read(servicesControllerProvider.notifier)
                                  .delete(service.id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ServiceItem> _filterServices(List<ServiceItem> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((s) {
      final name = s.name.toLowerCase();
      final desc = (s.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }
}
