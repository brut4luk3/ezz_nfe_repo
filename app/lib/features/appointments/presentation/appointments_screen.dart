import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_list_tile_with_options.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../../clients/data/client_model.dart';
import '../../clients/presentation/clients_providers.dart';
import '../../invoices/data/invoice_model.dart';
import '../../products/data/product_brand_model.dart';
import '../../products/data/product_model.dart';
import '../../products/presentation/product_brands_providers.dart';
import '../../products/presentation/products_providers.dart';
import '../../services_catalog/data/service_item_model.dart';
import '../../services_catalog/presentation/services_providers.dart';
import '../../invoices/presentation/invoices_providers.dart';
import '../data/appointment_model.dart';
import 'appointments_providers.dart';

String _clientName(String clientId, List<Client>? clients) {
  if (clients == null || clientId.isEmpty) return '—';
  for (final c in clients) {
    if (c.id == clientId) return c.name;
  }
  return '—';
}

String _serviceOrProductLabel(
  Appointment appt,
  List<ServiceItem>? services,
  List<Product>? products,
  List<ProductBrand>? brands,
) {
  if (!appt.isOnlySale && appt.serviceIds.isNotEmpty && services != null) {
    final serviceMap = {for (final s in services) s.id: s};
    final names = <String>[];
    for (final sid in appt.serviceIds) {
      final s = serviceMap[sid];
      if (s != null && s.name.isNotEmpty) names.add(s.name);
    }
    if (names.isNotEmpty) return names.join(', ');
  }
  if (appt.isOnlySale && appt.productItems.isNotEmpty && products != null) {
    final productMap = {for (final p in products) p.id: p};
    final brandMap = brands != null ? {for (final b in brands) b.id: b.name} : null;
    final first = appt.productItems.first;
    final p = productMap[first.productId];
    if (p != null) {
      return p.displayWithBrand(brandMap?[p.brandId] ?? p.brandLegacy);
    }
  }
  return '—';
}

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final clientsAsync = ref.watch(clientsListProvider);
    final servicesAsync = ref.watch(servicesListProvider);
    final productsAsync = ref.watch(productsListProvider);
    final brandsAsync = ref.watch(productBrandsListProvider);
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
            return _buildAppointmentsList(
              context,
              ref,
              appointments,
              clientsAsync.valueOrNull,
              servicesAsync.valueOrNull,
              productsAsync.valueOrNull,
              brandsAsync.valueOrNull,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    WidgetRef ref,
    List<Appointment> appointments,
    List<Client>? clients,
    List<ServiceItem>? services,
    List<Product>? products,
    List<ProductBrand>? brands,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return AppListTileWithOptions(
          title: _serviceOrProductLabel(appt, services, products, brands),
          subtitle: '${_clientName(appt.clientId, clients)} - ${formatDateTimeBr(appt.scheduledAt)}\n${formatCurrencyValue(appt.total)}',
          onTap: () => context.go('/appointments/${appt.id}'),
          options: const [
            AppListTileOption(
              value: 'invoice',
              label: 'Gerar nota (placeholder)',
              icon: Icons.receipt_long,
            ),
            AppListTileOption(
              value: 'delete',
              label: 'Remover',
              icon: Icons.delete,
            ),
          ],
          onOptionSelected: (value) async {
            if (!context.mounted) return;
            if (value == 'delete') {
              final ok = await showConfirmDialog(
                context: context,
                title: 'Remover atendimento',
                message:
                    'Tem certeza que deseja remover este atendimento?',
              );
              if (!ok || !context.mounted) return;
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
        );
      },
    );
  }

  Future<void> _createInvoicePlaceholder(
      WidgetRef ref, Appointment appt) async {
    final invoice = Invoice(
      id: '',
      appointmentId: appt.id,
      status: InvoiceStatus.pendingIntegration,
      totalCents: (appt.total * 100).round(),
    );
    await ref.read(invoicesControllerProvider.notifier).create(invoice);
  }
}
