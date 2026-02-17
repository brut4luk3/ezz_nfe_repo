import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../features/products/data/product_brand_model.dart';
import '../../../features/products/presentation/product_brands_providers.dart';
import 'app_text_field.dart';

/// Form compacto para adicionar marca de produto dentro do SelectDialog.
/// Campo obrigatório: Nome.
class SelectAddProductBrandForm extends ConsumerStatefulWidget {
  final void Function(Future<String?> Function() submit) registerSubmit;

  const SelectAddProductBrandForm({
    super.key,
    required this.registerSubmit,
  });

  @override
  ConsumerState<SelectAddProductBrandForm> createState() =>
      _SelectAddProductBrandFormState();
}

class _SelectAddProductBrandFormState
    extends ConsumerState<SelectAddProductBrandForm> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.registerSubmit(_submit);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<String?> _submit() async {
    setState(() => _error = null);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nome é obrigatório.');
      return null;
    }
    final repo = ref.read(productBrandsRepositoryProvider);
    if (repo == null) return null;
    final item = ProductBrand(id: '', name: name);
    final id = await repo.create(item);
    ref.invalidate(productBrandsListProvider);
    return id;
  }

  @override
  Widget build(BuildContext context) {
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
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
