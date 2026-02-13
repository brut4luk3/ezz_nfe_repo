import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../data/client_model.dart';
import 'clients_providers.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);
    final actionState = ref.watch(clientsControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/clients/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar cliente',
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
              child: clientsAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (clients) {
                  final filtered = _filterClients(clients, _query);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum cliente encontrado.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final client = filtered[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(client.name),
                          subtitle: Text(
                            _subtitle(client),
                          ),
                          onTap: () => context.go('/clients/${client.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showConfirmDialog(
                                context: context,
                                title: 'Remover cliente',
                                message:
                                    'Tem certeza que deseja remover este cliente?',
                              );
                              if (!ok) return;
                              await ref
                                  .read(clientsControllerProvider.notifier)
                                  .delete(client.id);
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

  List<Client> _filterClients(List<Client> clients, String query) {
    if (query.isEmpty) return clients;
    final q = query.toLowerCase();
    return clients.where((c) {
      final name = c.name.toLowerCase();
      final phone = (c.phone ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  String _subtitle(Client client) {
    final parts = <String>[];
    if (client.phone != null && client.phone!.isNotEmpty) {
      parts.add(client.phone!);
    }
    if (client.cpf != null && client.cpf!.isNotEmpty) {
      parts.add(client.cpf!);
    }
    if (parts.isEmpty) return 'Sem detalhes';
    return parts.join(' • ');
  }
}
