import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/components/select_add_product_form.dart';
import '../../../core/ui/components/select_dialog.dart';
import '../../../core/utils/brazilian_currency_formatter.dart';
import '../../../features/products/presentation/products_providers.dart';
import '../data/service_item_model.dart';
import 'services_providers.dart';

enum DurationUnit { minutes, hours }

class _ProductLine {
  String? productId;
  double quantity;
  _ProductLine({this.productId, this.quantity = 1});
}

class ServiceFormScreen extends ConsumerStatefulWidget {
  final String? serviceId;
  const ServiceFormScreen({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _durationFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  DurationUnit _durationUnit = DurationUnit.hours;
  List<_ProductLine> _productLines = [_ProductLine()];
  String? _localError;
  bool _userHasCleared = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = '0.00';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    _durationFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _userHasCleared = true;
      _nameController.clear();
      _priceController.text = '0.00';
      _durationController.clear();
      _descriptionController.clear();
      _durationUnit = DurationUnit.hours;
      _productLines = [_ProductLine()];
      _localError = null;
    });
  }

  void _setValues(ServiceItem item, {Set<String>? validProductIds}) {
    _nameController.text = item.name;
    _priceController.text = item.price.toStringAsFixed(2);
    _setDurationFromMinutes(item.durationMinutes);
    _descriptionController.text = item.description ?? '';
    var productItemsToUse = item.productItems;
    if (validProductIds != null) {
      productItemsToUse = productItemsToUse
          .where((p) => validProductIds.contains(p.productId))
          .toList();
    }
    _productLines = productItemsToUse.isEmpty
        ? [_ProductLine()]
        : productItemsToUse
            .map((p) =>
                _ProductLine(productId: p.productId, quantity: p.quantity))
            .toList();
  }

  void _setDurationFromMinutes(int? durationMinutes) {
    if (durationMinutes == null) {
      _durationController.clear();
      _durationUnit = DurationUnit.hours;
      return;
    }
    if (durationMinutes >= 60) {
      _durationController.text = (durationMinutes / 60).toStringAsFixed(
        durationMinutes % 60 == 0 ? 0 : 1,
      );
      _durationUnit = DurationUnit.hours;
    } else {
      _durationController.text = durationMinutes.toString();
      _durationUnit = DurationUnit.minutes;
    }
  }

  double? _parsePrice(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return value;
  }

  double? _parseDuration(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _durationToMinutes() {
    final v = _parseDuration(_durationController.text.trim());
    if (v == null || v < 0) return null;
    return (_durationUnit == DurationUnit.hours ? v * 60 : v).round();
  }

  bool _isFormValid() {
    final name = _nameController.text.trim();
    final price = _parsePrice(_priceController.text.trim());
    return name.isNotEmpty && price != null && price > 0;
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final name = _nameController.text.trim();
    final price = _parsePrice(_priceController.text.trim());
    if (name.isEmpty || price == null || price <= 0) {
      setState(() => _localError = 'Nome e preço são obrigatórios.');
      return;
    }
    final durationMinutes = _durationToMinutes();
    final productItems = _productLines
        .where((l) => l.productId != null && l.productId!.isNotEmpty)
        .map((l) => ServiceProductItem(
              productId: l.productId!,
              quantity: l.quantity >= 1 ? l.quantity : 1,
            ))
        .toList();

    final item = ServiceItem(
      id: widget.serviceId ?? '',
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      productItems: productItems,
    );

    final controller = ref.read(servicesControllerProvider.notifier);
    if (widget.serviceId == null) {
      await controller.create(item);
    } else {
      await controller.update(widget.serviceId!, item);
    }

    if (!mounted) return;
    final state = ref.read(servicesControllerProvider);
    if (state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo.')),
      );
      context.pop();
    }
  }

  Future<void> _pickProduct(int lineIndex) async {
    final products = ref.read(productsListProvider).valueOrNull ?? [];
    final excludedIds = _productLines
        .where((l) => l.productId != null && l.productId != '')
        .map((l) => l.productId!)
        .toSet();
    if (lineIndex < _productLines.length) {
      excludedIds.remove(_productLines[lineIndex].productId);
    }
    final options = products
        .where((p) => !excludedIds.contains(p.id))
        .map((p) => SelectOption<String>(value: p.id, label: p.name))
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
      setState(() {
        if (lineIndex < _productLines.length) {
          _productLines[lineIndex].productId = result.first;
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

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(servicesControllerProvider);

    if (widget.serviceId != null) {
      final serviceAsync = ref.watch(serviceByIdProvider(widget.serviceId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Editar serviço')),
        body: serviceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (item) {
            if (item != null &&
                _nameController.text.isEmpty &&
                !_userHasCleared) {
              final productsAsync = ref.watch(productsListProvider);
              final validIds = productsAsync.hasValue
                  ? (productsAsync.value ?? [])
                      .map((p) => p.id)
                      .toSet()
                  : null;
              _setValues(item, validProductIds: validIds);
            }
            return _form(actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo serviço')),
      body: _form(actionState),
    );
  }

  Widget _form(ServicesActionState actionState) {
    final products = ref.watch(productsListProvider).valueOrNull ?? [];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              children: [
                AppTextField(
                  label: 'Nome',
                  isRequired: true,
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocusNode: _priceFocus,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Preço',
                  isRequired: true,
                  controller: _priceController,
                  focusNode: _priceFocus,
                  nextFocusNode: _durationFocus,
                  prefixText: 'R\$ ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyDigitsFormatter()],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Duração',
                  isOptional: true,
                  controller: _durationController,
                  focusNode: _durationFocus,
                  nextFocusNode: _descriptionFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Unidade:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<DurationUnit>(
                      segments: const [
                        ButtonSegment(
                          value: DurationUnit.minutes,
                          label: Text('Minuto(s)'),
                        ),
                        ButtonSegment(
                          value: DurationUnit.hours,
                          label: Text('Hora(s)'),
                        ),
                      ],
                      selected: {_durationUnit},
                      onSelectionChanged: (s) =>
                          setState(() => _durationUnit = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Descrição',
                  isOptional: true,
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  'Produtos',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...List.generate(_productLines.length, (i) {
                  final line = _productLines[i];
                  final productName = line.productId != null
                      ? products
                              .where((p) => p.id == line.productId)
                              .map((p) => p.name)
                              .firstOrNull ??
                          'Selecione'
                      : 'Selecione';
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
                              child: Text(productName),
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
                                          line.quantity =
                                              (line.quantity - 1).clamp(1.0, double.infinity);
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
                            icon: const Icon(Icons.delete_outline),
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
                const SizedBox(height: 16),
                if (_localError != null) ...[
                  Text(
                    _localError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (actionState.errorMessage != null) ...[
                  Text(
                    actionState.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                onPressed: _submit,
                isLoading: actionState.isLoading,
                disabled: !_isFormValid(),
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
