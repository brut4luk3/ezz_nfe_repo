import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_date_field.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/components/select_add_product_brand_form.dart';
import '../../../core/ui/components/select_add_product_type_form.dart';
import '../../../core/ui/components/select_dialog.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/brazilian_currency_formatter.dart';
import '../data/product_model.dart';
import 'product_brands_providers.dart';
import 'product_types_providers.dart';
import 'products_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController();
  final _nameFocus = FocusNode();
  final _valueFocus = FocusNode();
  final _quantityFocus = FocusNode();
  String? _typeId;
  String? _brandId;
  ProductUnit? _unit;
  DateTime? _expiryDate;
  String? _localError;
  bool _userHasCleared = false;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    _nameFocus.dispose();
    _valueFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _userHasCleared = true;
      _nameController.clear();
      _valueController.clear();
      _quantityController.clear();
      _typeId = null;
      _brandId = null;
      _unit = null;
      _expiryDate = null;
      _localError = null;
    });
  }

  void _setValues(Product product) {
    _nameController.text = product.name;
    _brandId = product.brandId;
    _valueController.text = BrazilianCurrencyInputFormatter.formatFromCents(
      product.valueCents,
    );
    _quantityController.text = product.quantity?.toString() ?? '';
    _typeId = product.typeId;
    _unit = product.unit;
    _expiryDate = product.expiryDate;
  }

  int? _parseValueCents(String text) {
    return BrazilianCurrencyInputFormatter.parseToCents(text);
  }

  double? _parseQuantity(String text) {
    final normalized = text.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  bool _isFormValid() {
    final name = _nameController.text.trim();
    final valueCents = _parseValueCents(_valueController.text.trim());
    return name.isNotEmpty &&
        _brandId != null &&
        valueCents != null &&
        valueCents > 0;
  }

  Widget _buildTypeField() {
    final typesAsync = ref.watch(productTypesListProvider);
    final types = typesAsync.valueOrNull ?? [];
    return typesAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tipo (opcional)',
          border: OutlineInputBorder(),
        ),
        child: Text('Carregando...'),
      ),
      error: (_, _) => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tipo (opcional)',
          border: OutlineInputBorder(),
        ),
        child: Text('Erro ao carregar tipos'),
      ),
      data: (_) => SelectFormField<String>(
        label: 'Tipo',
        items: types
            .map((t) => SelectOption<String>(value: t.id, label: t.name))
            .toList(),
        multiple: false,
        value: _typeId != null ? [_typeId!] : [],
        onChanged: (v) =>
            setState(() => _typeId = v.isNotEmpty ? v.first : null),
        searchHint: 'Buscar tipo',
        isOptional: true,
        buildAddForm: (context, ref, registerSubmit) =>
            SelectAddProductTypeForm(registerSubmit: registerSubmit),
      ),
    );
  }

  Widget _buildBrandField() {
    final brandsAsync = ref.watch(productBrandsListProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    return brandsAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Marca *',
          border: OutlineInputBorder(),
        ),
        child: Text('Carregando...'),
      ),
      error: (_, _) => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Marca *',
          border: OutlineInputBorder(),
        ),
        child: Text('Erro ao carregar marcas'),
      ),
      data: (_) => SelectFormField<String>(
        label: 'Marca',
        items: brands
            .map((b) => SelectOption<String>(value: b.id, label: b.name))
            .toList(),
        multiple: false,
        value: _brandId != null ? [_brandId!] : [],
        onChanged: (v) =>
            setState(() => _brandId = v.isNotEmpty ? v.first : null),
        searchHint: 'Buscar marca',
        isRequired: true,
        buildAddForm: (context, ref, registerSubmit) =>
            SelectAddProductBrandForm(registerSubmit: registerSubmit),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final name = _nameController.text.trim();
    final valueCents = _parseValueCents(_valueController.text.trim());
    if (name.isEmpty) {
      setState(() => _localError = 'Nome é obrigatório.');
      return;
    }
    if (_brandId == null) {
      setState(() => _localError = 'Marca é obrigatória.');
      return;
    }
    if (valueCents == null || valueCents <= 0) {
      setState(
        () => _localError = 'Valor é obrigatório e deve ser maior que zero.',
      );
      return;
    }

    final quantity = _parseQuantity(_quantityController.text.trim());
    if (quantity != null && quantity < 0) {
      setState(() => _localError = 'Quantidade não pode ser negativa.');
      return;
    }

    final product = Product(
      id: widget.productId ?? '',
      name: name,
      brandId: _brandId,
      valueCents: valueCents,
      typeId: _typeId,
      quantity: quantity,
      unit: _unit,
      expiryDate: _expiryDate,
    );

    final controller = ref.read(productsControllerProvider.notifier);
    if (widget.productId == null) {
      await controller.create(product);
    } else {
      await controller.update(widget.productId!, product);
    }

    if (!mounted) return;
    final state = ref.read(productsControllerProvider);
    if (state.errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produto salvo.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(productsControllerProvider);

    if (widget.productId != null) {
      final productAsync = ref.watch(productByIdProvider(widget.productId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Editar produto')),
        body: productAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (product) {
            if (product != null &&
                _nameController.text.isEmpty &&
                !_userHasCleared) {
              _setValues(product);
            }
            return _form(actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo produto')),
      body: _form(actionState),
    );
  }

  Widget _form(ProductsActionState actionState) {
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
                  nextFocusNode: _valueFocus,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _buildTypeField(),
                const SizedBox(height: 12),
                _buildBrandField(),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Valor',
                  isRequired: true,
                  controller: _valueController,
                  focusNode: _valueFocus,
                  nextFocusNode: _quantityFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [BrazilianCurrencyInputFormatter()],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Quantidade',
                  isOptional: true,
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SelectFormField<ProductUnit?>(
                  label: 'Unidade',
                  items: [
                    const SelectOption<ProductUnit?>(
                      value: null,
                      label: 'Nenhuma',
                    ),
                    ...ProductUnit.values.map(
                      (u) => SelectOption<ProductUnit?>(
                        value: u,
                        label: '${u.label} (${u.code})',
                      ),
                    ),
                  ],
                  multiple: false,
                  value: _unit != null ? [_unit!] : [],
                  onChanged: (v) =>
                      setState(() => _unit = v.isNotEmpty ? v.first : null),
                  searchHint: 'Buscar unidade',
                  isOptional: true,
                ),
                const SizedBox(height: 12),
                AppDateField(
                  label: 'Validade',
                  isOptional: true,
                  value: _expiryDate,
                  onChanged: (v) => setState(() => _expiryDate = v),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
