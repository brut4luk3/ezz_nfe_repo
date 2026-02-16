import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/services_catalog/data/service_item_model.dart';
import '../../../features/services_catalog/presentation/services_providers.dart';
import 'app_text_field.dart';

/// Form compacto para adicionar serviço dentro do SelectDialog.
/// Apenas campos obrigatórios: Nome, Preço.
class SelectAddServiceForm extends ConsumerStatefulWidget {
  final void Function(Future<String?> Function() submit) registerSubmit;

  const SelectAddServiceForm({
    super.key,
    required this.registerSubmit,
  });

  @override
  ConsumerState<SelectAddServiceForm> createState() => _SelectAddServiceFormState();
}

class _SelectAddServiceFormState extends ConsumerState<SelectAddServiceForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
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
    _priceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  int? _parsePriceCents(String text) {
    final normalized = text.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }

  Future<String?> _submit() async {
    setState(() => _error = null);
    final name = _nameController.text.trim();
    final priceCents = _parsePriceCents(_priceController.text.trim());
    if (name.isEmpty || priceCents == null) {
      setState(() => _error = 'Nome e preco sao obrigatorios.');
      return null;
    }
    final item = ServiceItem(
      id: '',
      name: name,
      priceCents: priceCents,
      addedViaSelectDialog: true,
    );
    final controller = ref.read(servicesControllerProvider.notifier);
    final id = await controller.create(item);
    if (id != null) ref.invalidate(servicesListProvider);
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
          nextFocusNode: _priceFocus,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Preco (ex: 49.90)',
          isRequired: true,
          controller: _priceController,
          focusNode: _priceFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
