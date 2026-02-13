import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/status_badge.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../data/invoice_model.dart';
import 'invoices_providers.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider);
    final actionState = ref.watch(invoicesControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final invoice = Invoice(
            id: '',
            status: InvoiceStatus.pendingIntegration,
            totalCents: 0,
          );
          await ref.read(invoicesControllerProvider.notifier).create(invoice);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Integracao Focus NFe ainda nao configurada.'),
            ),
          );
        },
        label: const Text('Gerar Nota'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: invoicesAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(message: err.toString()),
          data: (invoices) {
            if (actionState.errorMessage != null) {
              return Center(child: Text(actionState.errorMessage!));
            }
            if (invoices.isEmpty) {
              return const Center(child: Text('Nenhuma nota encontrada.'));
            }
            return ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return AppCard(
                  child: ListTile(
                    title: Text(
                      invoice.appointmentId == null
                          ? 'Nota sem atendimento'
                          : 'Nota do atendimento ${invoice.appointmentId}',
                    ),
                    subtitle: Text(formatCurrency(invoice.totalCents)),
                    trailing: StatusBadge(
                      label: _statusLabel(invoice.status),
                      color: _statusColor(invoice.status),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pendingIntegration:
        return 'Pendente';
      case InvoiceStatus.issued:
        return 'Emitida';
      case InvoiceStatus.error:
        return 'Erro';
    }
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pendingIntegration:
        return Colors.orange;
      case InvoiceStatus.issued:
        return Colors.green;
      case InvoiceStatus.error:
        return Colors.red;
    }
  }
}
