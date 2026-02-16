// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/components/select_dialog.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../../clients/data/client_model.dart';
import '../../clients/presentation/clients_providers.dart';
import '../../services_catalog/data/service_item_model.dart';
import '../../services_catalog/presentation/services_providers.dart';
import '../data/appointment_model.dart';
import 'appointments_providers.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  String? _clientId;
  final Set<String> _serviceIds = {};
  DateTime _scheduledAt = DateTime.now();
  final _notesController = TextEditingController();
  String? _localError;
  bool _userHasCleared = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _userHasCleared = true;
      _clientId = null;
      _serviceIds.clear();
      _scheduledAt = DateTime.now();
      _notesController.clear();
      _localError = null;
    });
  }

  void _setValues(Appointment appt) {
    _clientId = appt.clientId;
    _serviceIds
      ..clear()
      ..addAll(appt.serviceIds);
    _scheduledAt = appt.scheduledAt;
    _notesController.text = appt.notes ?? '';
  }

  int _totalCents(List<ServiceItem> services) {
    var total = 0;
    for (final s in services) {
      if (_serviceIds.contains(s.id)) {
        total += s.priceCents;
      }
    }
    return total;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit(List<ServiceItem> services) async {
    setState(() => _localError = null);
    if (_clientId == null) {
      setState(() => _localError = 'Selecione um cliente.');
      return;
    }
    if (_serviceIds.isEmpty) {
      setState(() => _localError = 'Selecione ao menos um servico.');
      return;
    }
    final total = _totalCents(services);
    final appt = Appointment(
      id: widget.appointmentId ?? '',
      clientId: _clientId!,
      serviceIds: _serviceIds.toList(),
      totalCents: total,
      scheduledAt: _scheduledAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(appointmentsControllerProvider.notifier);
    if (widget.appointmentId == null) {
      await controller.create(appt);
    } else {
      await controller.update(widget.appointmentId!, appt);
    }

    if (!mounted) return;
    final state = ref.read(appointmentsControllerProvider);
    if (state.errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Atendimento salvo.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);
    final servicesAsync = ref.watch(servicesListProvider);
    final actionState = ref.watch(appointmentsControllerProvider);

    if (widget.appointmentId != null) {
      final apptAsync = ref.watch(
        appointmentByIdProvider(widget.appointmentId!),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Editar atendimento')),
        body: apptAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (appt) {
            if (appt != null && _clientId == null && !_userHasCleared) {
              _setValues(appt);
            }
            return _form(clientsAsync, servicesAsync, actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo atendimento')),
      body: _form(clientsAsync, servicesAsync, actionState),
    );
  }

  Widget _form(
    AsyncValue<List<Client>> clientsAsync,
    AsyncValue<List<ServiceItem>> servicesAsync,
    AppointmentsActionState actionState,
  ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              children: [
          clientsAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => Text(err.toString()),
            data: (clients) {
              if (clients.isEmpty) {
                return const Text('Cadastre um cliente primeiro.');
              }
              return SelectFormField<String>(
                label: 'Cliente',
                items: clients
                    .map((c) => SelectOption<String>(value: c.id, label: c.name))
                    .toList(),
                multiple: false,
                value: _clientId != null ? [_clientId!] : [],
                onChanged: (v) =>
                    setState(() => _clientId = v.isNotEmpty ? v.first : null),
                searchHint: 'Buscar cliente',
                isRequired: true,
              );
            },
          ),
          const SizedBox(height: 12),
          servicesAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => Text(err.toString()),
            data: (services) {
              if (services.isEmpty) {
                return const Text('Cadastre um servico primeiro.');
              }
              final total = _totalCents(services);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectFormField<String>(
                    label: 'Servicos',
                    items: services
                        .map((s) => SelectOption<String>(
                              value: s.id,
                              label: s.name,
                              subtitle: formatCurrency(s.priceCents),
                            ))
                        .toList(),
                    multiple: true,
                    value: _serviceIds.toList(),
                    onChanged: (v) => setState(() {
                      _serviceIds.clear();
                      _serviceIds.addAll(v);
                    }),
                    searchHint: 'Buscar servico',
                    isRequired: true,
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ${formatCurrency(total)}'),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data e hora'),
            subtitle: Text(formatDateTime(_scheduledAt)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Observacoes',
            isOptional: true,
            controller: _notesController,
            textInputAction: TextInputAction.send,
          ),
          const SizedBox(height: 16),
          if (_localError != null) ...[
            Text(_localError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          if (actionState.errorMessage != null) ...[
            Text(
              actionState.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
          ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                icon: Icons.save,
                label: 'Salvar',
                onPressed: (_clientId != null && _serviceIds.isNotEmpty)
                    ? () => servicesAsync.when(
                          loading: () {},
                          error: (_, _) {},
                          data: (services) => _submit(services),
                        )
                    : null,
                isLoading: actionState.isLoading,
                disabled: _clientId == null || _serviceIds.isEmpty,
              ),
              const SizedBox(height: 8),
              FormClearLink(onTap: _clear),
            ],
          ),
        ),
      ],
    );
  }
}
