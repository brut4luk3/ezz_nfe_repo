import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/products/data/product_model.dart';
import '../../../features/products/data/product_brand_model.dart';
import '../../../features/products/presentation/product_brands_providers.dart';
import '../../../features/products/presentation/products_providers.dart';
import '../../../core/utils/brazilian_currency_formatter.dart';
import 'app_text_field.dart';
import 'select_add_product_brand_form.dart';
import 'select_dialog.dart';

/// Form compacto para adicionar produto dentro do SelectDialog.
/// Apenas campos obrigatórios: Nome, Marca, Valor. addedViaSelectDialog = true.
class SelectAddProductForm extends ConsumerStatefulWidget {
  final void Function(Future<String?> Function() submit) registerSubmit;

  const SelectAddProductForm({
    super.key,
    required this.registerSubmit,
  });

  @override
  ConsumerState<SelectAddProductForm> createState() =>
      _SelectAddProductFormState();
}

class _SelectAddProductFormState extends ConsumerState<SelectAddProductForm> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _nameFocus = FocusNode();
  final _valueFocus = FocusNode();
  String? _brandId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _valueController.text = '0.00';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.registerSubmit(_submit);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _nameFocus.dispose();
    _valueFocus.dispose();
    super.dispose();
  }

  double? _parseValue(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return value;
  }

  Future<String?> _submit() async {
    setState(() => _error = null);
    final name = _nameController.text.trim();
    final value = _parseValue(_valueController.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Nome é obrigatório.');
      return null;
    }
    if (_brandId == null) {
      setState(() => _error = 'Marca é obrigatória.');
      return null;
    }
    if (value == null || value <= 0) {
      setState(() => _error = 'Valor é obrigatório e deve ser maior que zero.');
      return null;
    }
    final controller = ref.read(productsControllerProvider.notifier);
    final product = Product(
      id: '',
      name: name,
      brandId: _brandId,
      value: value,
      addedViaSelectDialog: true,
    );
    final id = await controller.create(product);
    if (id != null) ref.invalidate(productsListProvider);
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(productBrandsListProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Nome',
          isRequired: true,
          controller: _nameController,
          focusNode: _nameFocus,
          nextFocusNode: _valueFocus,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _buildBrandField(brands),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Valor',
          isRequired: true,
          controller: _valueController,
          focusNode: _valueFocus,
          prefixText: 'R\$ ',
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyDigitsFormatter()],
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildBrandField(List<ProductBrand> brands) {
    final options = brands
        .map((b) => SelectOption<String>(value: b.id, label: b.name))
        .toList();
    return SelectFormField<String>(
      label: 'Marca',
      items: options,
      multiple: false,
      value: _brandId != null ? [_brandId!] : [],
      onChanged: (v) => setState(() => _brandId = v.isNotEmpty ? v.first : null),
      searchHint: 'Buscar marca',
      isRequired: true,
      buildAddForm: (ctx, r, registerSubmit) =>
          SelectAddProductBrandForm(registerSubmit: registerSubmit),
    );
  }
}
