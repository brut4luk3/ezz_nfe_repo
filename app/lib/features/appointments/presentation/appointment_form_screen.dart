// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_date_field.dart';
import '../../../core/ui/components/app_list_tile_with_delete.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/components/select_add_client_form.dart';
import '../../../core/ui/components/select_add_product_form.dart';
import '../../../core/ui/components/select_add_service_form.dart';
import '../../../core/ui/components/select_dialog.dart';
import '../../../core/utils/brazilian_currency_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../features/products/data/product_model.dart';
import '../../../features/products/presentation/product_brands_providers.dart';
import '../../../features/products/presentation/products_providers.dart';
import '../../clients/data/client_model.dart';
import '../../clients/presentation/clients_providers.dart';
import '../../services_catalog/data/service_item_model.dart';
import '../../services_catalog/presentation/services_providers.dart';
import '../../../app/di/providers.dart';
import '../data/appointment_model.dart';
import '../data/google_calendar_service.dart';
import 'appointments_providers.dart';

class _ProductLine {
  String? productId;
  String productName;
  double quantity;
  _ProductLine({this.productId, this.productName = '', this.quantity = 1});
}

/// Diálogo para editar o valor total. Usa StatefulWidget para que o controller
/// seja descartado apenas quando o diálogo for removido da árvore.
class _EditTotalDialogContent extends StatefulWidget {
  final TextEditingController controller;

  const _EditTotalDialogContent({required this.controller});

  @override
  State<_EditTotalDialogContent> createState() =>
      _EditTotalDialogContentState();
}

class _EditTotalDialogContentState extends State<_EditTotalDialogContent> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar valor total'),
      content: AppTextField(
        label: 'Total',
        controller: widget.controller,
        prefixText: 'R\$ ',
        keyboardType: TextInputType.number,
        inputFormatters: [CurrencyDigitsFormatter()],
        onChanged: (_) {},
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text =
                widget.controller.text.trim().replaceAll(',', '.');
            final value = double.tryParse(text);
            if (value != null && value >= 0) {
              Navigator.of(context).pop<double>(value);
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  String? _clientId;
  bool _isOnlySale = false;
  List<String?> _serviceLines = [null];
  List<_ProductLine> _productLines = [_ProductLine()];
  DateTime _scheduledAt = DateTime.now();
  bool _chargeDeposit = false;
  /// Marcar na Google Agenda. Apenas para agendamentos de serviços (!isOnlySale).
  bool _addToCalendar = true;
  String? _calendarEventId;
  /// Total editado manualmente pelo usuário. Null = usar o calculado.
  double? _totalOverride;
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();
  String? _localError;
  bool _userHasCleared = false;

  @override
  void initState() {
    super.initState();
    _depositController.text = '0.00';
  }

  @override
  void dispose() {
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _userHasCleared = true;
      _clientId = null;
      _isOnlySale = false;
      _serviceLines = [null];
      _productLines = [_ProductLine()];
      _scheduledAt = DateTime.now();
      _chargeDeposit = false;
      _addToCalendar = true;
      _calendarEventId = null;
      _totalOverride = null;
      _depositController.text = '0.00';
      _notesController.clear();
      _localError = null;
    });
  }

  void _setValues(Appointment appt) {
    _clientId = appt.clientId;
    _isOnlySale = appt.isOnlySale;
    _serviceLines = appt.serviceItems.isEmpty
        ? [null]
        : appt.serviceItems.map<String?>((s) => s.serviceId).toList();
    _productLines = appt.productItems.isEmpty
        ? [_ProductLine()]
        : appt.productItems
            .map((p) => _ProductLine(
                  productId: p.productId,
                  productName: p.productName,
                  quantity: p.quantity,
                ))
            .toList();
    _scheduledAt = appt.scheduledAt;
    _chargeDeposit = appt.chargeDeposit;
    _addToCalendar = appt.addToCalendar;
    _calendarEventId = appt.calendarEventId;
    _totalOverride = appt.total;
    _depositController.text =
        appt.deposit != null ? appt.deposit!.toStringAsFixed(2) : '0.00';
    _notesController.text = appt.notes ?? '';
  }

  double _totalValue(
    List<ServiceItem> services,
    List<Product> products,
  ) {
    var total = 0.0;
    if (!_isOnlySale) {
      for (final s in services) {
        if (_serviceLines.contains(s.id)) {
          total += s.price;
        }
      }
    }
    final productMap = {for (final p in products) p.id: p};
    for (final line in _productLines) {
      if (line.productId != null && line.productId!.isNotEmpty) {
        final p = productMap[line.productId];
        if (p != null) {
          total += p.value * line.quantity;
        }
      }
    }
    return total;
  }

  double? _parseDeposit() {
    final text = _depositController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return 0.0;
    final value = double.tryParse(text);
    if (value == null || value < 0) return null;
    return value;
  }

  Future<void> _showEditTotalDialog(double currentTotal) async {
    final controller = TextEditingController(
      text: currentTotal.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => _EditTotalDialogContent(
        controller: controller,
      ),
    );
    if (result != null && mounted) {
      setState(() => _totalOverride = result);
    }
  }

  /// Retorna true para usar o valor calculado, false para manter o informado.
  Future<bool?> _showTotalLessThanSumDialog(double calculatedSum) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valor total'),
        content: Text(
          'O valor total informado é menor que a soma dos serviços e produtos.\n\n'
          'O valor calculado seria ${formatCurrencyValue(calculatedSum)}.\n\n'
          'Deseja salvar com esse valor total ou manter o valor informado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Manter valor informado'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usar valor calculado'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickService(int lineIndex) async {
    final services = ref.read(servicesListProvider).valueOrNull ?? [];
    final excludedIds = _serviceLines
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet();
    if (lineIndex < _serviceLines.length) {
      excludedIds.remove(_serviceLines[lineIndex]);
    }
    final options = services
        .where((s) => !excludedIds.contains(s.id))
        .map((s) => SelectOption<String>(
              value: s.id,
              label: s.name,
              subtitle: formatCurrencyValue(s.price),
            ))
        .toList();
    final result = await showSelectDialog<String>(
      context: context,
      ref: ref,
      items: options,
      multiple: false,
      searchHint: 'Buscar serviço',
      buildAddForm: (ctx, r, registerSubmit) =>
          SelectAddServiceForm(registerSubmit: registerSubmit),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (lineIndex < _serviceLines.length) {
          _serviceLines[lineIndex] = result.first;
        }
      });
    }
  }

  void _addServiceLine() {
    setState(() => _serviceLines.add(null));
  }

  void _removeServiceLine(int index) {
    if (_serviceLines.length > 1) {
      setState(() => _serviceLines.removeAt(index));
    }
  }

  Future<void> _pickProduct(int lineIndex) async {
    final products = ref.read(productsListProvider).valueOrNull ?? [];
    final excludedIds = _productLines
        .where((l) => l.productId != null && l.productId!.isNotEmpty)
        .map((l) => l.productId!)
        .toSet();
    if (lineIndex < _productLines.length) {
      excludedIds.remove(_productLines[lineIndex].productId);
    }
    final brands = ref.read(productBrandsListProvider).valueOrNull ?? [];
    final brandMap = {for (final b in brands) b.id: b.name};
    final options = products
        .where((p) => !excludedIds.contains(p.id))
        .map((p) => SelectOption<String>(
              value: p.id,
              label: p.displayWithBrand(p.brandId != null ? brandMap[p.brandId] : p.brandLegacy),
            ))
        .toList();
    final result = await showSelectDialog<String>(
      context: context,
      ref: ref,
      items: options,
      multiple: false,
      searchHint: 'Buscar produto',
      buildAddForm: (ctx, r, registerSubmit) =>
          SelectAddProductForm(registerSubmit: registerSubmit),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final productId = result.first;
      final product = products.firstWhere((p) => p.id == productId);
      setState(() {
        if (lineIndex < _productLines.length) {
          _productLines[lineIndex].productId = productId;
          _productLines[lineIndex].productName = product.name;
        }
      });
    }
  }

  void _addProductLine() {
    setState(() => _productLines.add(_ProductLine()));
  }

  void _removeProductLine(int index) {
    if (_productLines.length > 1) {
      setState(() => _productLines.removeAt(index));
    }
  }

  bool _hasServicesOrProducts() {
    if (_isOnlySale) {
      return _productLines.any(
          (l) => (l.productId ?? '').trim().isNotEmpty);
    }
    final hasService =
        _serviceLines.any((s) => (s ?? '').trim().isNotEmpty);
    final hasProduct = _productLines.any(
        (l) => (l.productId ?? '').trim().isNotEmpty);
    return hasService || hasProduct;
  }

  Future<void> _submit(
    List<ServiceItem> services,
    List<Product> products,
    List<Client> clients,
  ) async {
    setState(() => _localError = null);
    if (_clientId == null) {
      setState(() => _localError = 'Selecione um cliente.');
      return;
    }
    if (!_hasServicesOrProducts()) {
      setState(() => _localError =
          _isOnlySale
              ? 'Adicione ao menos um produto.'
              : 'Adicione ao menos um serviço ou produto.');
      return;
    }
    if (_chargeDeposit) {
      final deposit = _parseDeposit();
      if (deposit == null) {
        setState(() => _localError = 'Valor do sinal inválido.');
        return;
      }
    }
    final serviceMap = {for (final s in services) s.id: s};
    final serviceItems = _serviceLines
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .map((id) => AppointmentServiceItem(
              serviceId: id,
              serviceName: serviceMap[id]?.name ?? '',
            ))
        .toList();
    final productMap = {for (final p in products) p.id: p};
    final productItems = _productLines
        .where((l) => (l.productId ?? '').trim().isNotEmpty)
        .map((l) {
          final p = productMap[l.productId];
          final name = l.productName.isNotEmpty
              ? l.productName
              : (p?.name ?? '');
          return AppointmentProductItem(
            productId: l.productId!,
            productName: name,
            quantity: l.quantity >= 1 ? l.quantity : 1,
          );
        })
        .toList();
    final calculatedSum = _totalValue(services, products);
    var effectiveTotal = _totalOverride ?? calculatedSum;
    if (effectiveTotal < calculatedSum && calculatedSum > 0) {
      final useCalculated = await _showTotalLessThanSumDialog(calculatedSum);
      if (!mounted) return;
      if (useCalculated == true) {
        effectiveTotal = calculatedSum;
      }
    }
    final deposit = _chargeDeposit ? _parseDeposit() : null;
    final appt = Appointment(
      id: widget.appointmentId ?? '',
      clientId: _clientId!,
      isOnlySale: _isOnlySale,
      serviceItems: serviceItems,
      productItems: productItems,
      total: effectiveTotal,
      scheduledAt: _scheduledAt,
      chargeDeposit: _chargeDeposit,
      deposit: deposit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      addToCalendar: _addToCalendar,
      calendarEventId: _calendarEventId,
    );

    final controller = ref.read(appointmentsControllerProvider.notifier);
    String? createdId;
    if (widget.appointmentId == null) {
      createdId = await controller.create(appt);
    } else {
      await controller.update(widget.appointmentId!, appt);
    }

    if (!mounted) return;
    final state = ref.read(appointmentsControllerProvider);
    if (state.errorMessage == null) {
      if (appt.canAddToCalendar && createdId != null) {
        final client = clients.firstWhere((c) => c.id == _clientId);
        final calendarService = ref.read(googleCalendarServiceProvider);
        final result = await calendarService.createEvent(
          appointment: appt.copyWith(id: createdId),
          client: client,
        );
        if (kDebugMode) {
          debugPrint('[GoogleCalendar] Resultado createEvent: $result');
          debugPrint('[GoogleCalendar] Tipo: ${result.runtimeType}');
          switch (result) {
            case GoogleCalendarSuccess(:final eventId):
              debugPrint('[GoogleCalendar] Success - eventId: $eventId');
              break;
            case GoogleCalendarUserCancelled():
              debugPrint('[GoogleCalendar] UserCancelled - usuário cancelou ou não autorizou');
              break;
            case GoogleCalendarError(:final message):
              debugPrint('[GoogleCalendar] Error - message: $message');
              break;
          }
        }
        if (!mounted) return;
        switch (result) {
          case GoogleCalendarSuccess(:final eventId):
            if (eventId.isNotEmpty) {
              await controller.update(
                createdId,
                appt.copyWith(id: createdId, calendarEventId: eventId),
              );
            }
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Atendimento salvo. Evento criado na agenda.'),
              ),
            );
            break;
          case GoogleCalendarUserCancelled():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Atendimento salvo. Para adicionar à agenda, autorize o acesso na próxima vez.',
                ),
              ),
            );
            break;
          case GoogleCalendarError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Atendimento salvo. $message'),
                backgroundColor: Colors.orange,
              ),
            );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atendimento salvo.')),
        );
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);
    final servicesAsync = ref.watch(servicesListProvider);
    final productsAsync = ref.watch(productsListProvider);
    final actionState = ref.watch(appointmentsControllerProvider);

    if (widget.appointmentId != null) {
      final apptAsync = ref.watch(
        appointmentByIdProvider(widget.appointmentId!),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Editar atendimento')),
        body: apptAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (appt) {
            if (appt != null && _clientId == null && !_userHasCleared) {
              _setValues(appt);
            }
            return _form(
                clientsAsync, servicesAsync, productsAsync, actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo atendimento')),
      body: _form(clientsAsync, servicesAsync, productsAsync, actionState),
    );
  }

  Widget _form(
    AsyncValue<List<Client>> clientsAsync,
    AsyncValue<List<ServiceItem>> servicesAsync,
    AsyncValue<List<Product>> productsAsync,
    AppointmentsActionState actionState,
  ) {
    final services = servicesAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final brands = ref.watch(productBrandsListProvider).valueOrNull ?? [];
    final brandMap = {for (final b in brands) b.id: b.name};
    final total = _totalValue(services, products);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.manual,
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
                        .map((c) =>
                            SelectOption<String>(value: c.id, label: c.name))
                        .toList(),
                    multiple: false,
                    value: _clientId != null ? [_clientId!] : [],
                    onChanged: (v) =>
                        setState(() => _clientId = v.isNotEmpty ? v.first : null),
                    searchHint: 'Buscar cliente',
                    isRequired: true,
                    buildAddForm: (context, ref, registerSubmit) =>
                        SelectAddClientForm(registerSubmit: registerSubmit),
                  );
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('É apenas venda'),
                value: _isOnlySale,
                onChanged: (v) => setState(() => _isOnlySale = v),
              ),
              if (!_isOnlySale) ...[
                const SizedBox(height: 12),
                ...List.generate(_serviceLines.length, (i) {
                  final sid = _serviceLines[i];
                  final serviceName = sid != null
                      ? (services
                              .where((s) => s.id == sid)
                              .firstOrNull
                              ?.name ??
                          'Selecione')
                      : 'Selecione';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickService(i),
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Serviço',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(serviceName),
                            ),
                          ),
                        ),
                        if (_serviceLines.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: kDeleteIconColor,
                            ),
                            onPressed: () => _removeServiceLine(i),
                          ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _addServiceLine,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Adicionar mais serviços',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ...List.generate(_productLines.length, (i) {
                final line = _productLines[i];
                final prod = line.productId != null
                    ? products
                        .where((p) => p.id == line.productId)
                        .firstOrNull
                    : null;
                final productDisplay = prod != null
                    ? prod.displayWithBrand(
                        prod.brandId != null
                            ? brandMap[prod.brandId]
                            : prod.brandLegacy)
                    : (line.productName.isNotEmpty ? line.productName : 'Selecione');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () => _pickProduct(i),
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Produto',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                              child: Text(productDisplay),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: line.quantity <= 1
                                  ? null
                                  : () => setState(() {
                                        line.quantity = (line.quantity - 1)
                                            .clamp(1.0, double.infinity);
                                      }),
                            ),
                            Expanded(
                              child: Text(
                                line.quantity == line.quantity.round()
                                    ? line.quantity.toInt().toString()
                                    : line.quantity.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() {
                                line.quantity += 1;
                              }),
                            ),
                          ],
                        ),
                      ),
                      if (_productLines.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: kDeleteIconColor,
                          ),
                          onPressed: () => _removeProductLine(i),
                        ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: _addProductLine,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Adicionar mais itens',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_isOnlySale) ...[
                AppDateField(
                  label: 'Data e hora',
                  isRequired: true,
                  value: _scheduledAt,
                  onChanged: (v) => setState(() {
                    if (v != null) _scheduledAt = v;
                  }),
                  includeTime: true,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marcar na agenda'),
                  subtitle: const Text(
                    'Criar evento na Google Agenda (será solicitada autorização)',
                  ),
                  value: _addToCalendar,
                  onChanged: (v) => setState(() => _addToCalendar = v),
                ),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cobrar sinal'),
                value: _chargeDeposit,
                onChanged: (v) => setState(() => _chargeDeposit = v),
              ),
              if (_chargeDeposit) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Valor do sinal',
                  isRequired: true,
                  controller: _depositController,
                  prefixText: 'R\$ ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyDigitsFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Observações',
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrencyValue(
                              _totalOverride ?? total),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditTotalDialog(
                            _totalOverride ?? total,
                          ),
                          tooltip: 'Editar valor total',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                icon: Icons.save,
                label: 'Salvar',
                onPressed: _clientId != null && _hasServicesOrProducts()
                    ? () async {
                        final s = ref.read(servicesListProvider).valueOrNull;
                        final p = ref.read(productsListProvider).valueOrNull;
                        final c = clientsAsync.valueOrNull;
                        if (s != null && p != null && c != null) {
                          await _submit(s, p, c);
                        }
                      }
                    : null,
                isLoading: actionState.isLoading,
                disabled:
                    _clientId == null || !_hasServicesOrProducts(),
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
