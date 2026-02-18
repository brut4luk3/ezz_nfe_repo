import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../../invoices/data/invoice_model.dart';
import '../../invoices/presentation/invoices_providers.dart';
import '../data/appointment_model.dart';
import 'appointments_providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/appointments/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: appointmentsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(message: err.toString()),
          data: (appointments) {
            if (appointments.isEmpty) {
              return const Center(
                child: Text('Nenhum atendimento encontrado.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return AppCard(
                  child: ListTile(
                    title: Text('Atendimento ${formatDateTime(appt.scheduledAt)}'),
                    subtitle: Text(formatCurrency(appt.totalCents)),
                    onTap: () => context.go('/appointments/${appt.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final ok = await showConfirmDialog(
                            context: context,
                            title: 'Remover atendimento',
                            message:
                                'Tem certeza que deseja remover este atendimento?',
                          );
                          if (!ok) return;
                          await ref
                              .read(appointmentsControllerProvider.notifier)
                              .delete(appt.id);
                        }
                        if (value == 'invoice') {
                          await _createInvoicePlaceholder(ref, appt);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Integracao Focus NFe ainda nao configurada.'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'invoice',
                          child: Text('Gerar nota (placeholder)'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Remover'),
                        ),
                      ],
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

  Future<void> _createInvoicePlaceholder(
      WidgetRef ref, Appointment appt) async {
    final invoice = Invoice(
      id: '',
      appointmentId: appt.id,
      status: InvoiceStatus.pendingIntegration,
      totalCents: appt.totalCents,
    );
    await ref.read(invoicesControllerProvider.notifier).create(invoice);
  }
}
