import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../data/service_item_model.dart';
import 'services_providers.dart';

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
  String? _localError;

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

  void _setValues(ServiceItem item) {
    _nameController.text = item.name;
    _priceController.text = (item.priceCents / 100).toStringAsFixed(2);
    _durationController.text =
        item.durationMinutes == null ? '' : item.durationMinutes.toString();
    _descriptionController.text = item.description ?? '';
  }

  int? _parsePriceCents(String text) {
    final normalized = text.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }

  bool _isFormValid() {
    final name = _nameController.text.trim();
    final priceCents = _parsePriceCents(_priceController.text.trim());
    return name.isNotEmpty && priceCents != null;
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final name = _nameController.text.trim();
    final priceCents = _parsePriceCents(_priceController.text.trim());
    if (name.isEmpty || priceCents == null) {
      setState(() => _localError = 'Nome e preco sao obrigatorios.');
      return;
    }
    final duration = int.tryParse(_durationController.text.trim());

    final item = ServiceItem(
      id: widget.serviceId ?? '',
      name: name,
      priceCents: priceCents,
      durationMinutes: duration,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
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
        const SnackBar(content: Text('Servico salvo.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(servicesControllerProvider);

    if (widget.serviceId != null) {
      final serviceAsync = ref.watch(serviceByIdProvider(widget.serviceId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Editar servico')),
        body: serviceAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (item) {
            if (item != null && _nameController.text.isEmpty) {
              _setValues(item);
            }
            return _form(actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo servico')),
      body: _form(actionState),
    );
  }

  Widget _form(ServicesActionState actionState) {
    return Padding(
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
            label: 'Preco (ex: 49.90)',
            isRequired: true,
            controller: _priceController,
            focusNode: _priceFocus,
            nextFocusNode: _durationFocus,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Duracao (min)',
            isOptional: true,
            controller: _durationController,
            focusNode: _durationFocus,
            nextFocusNode: _descriptionFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Descricao',
            isOptional: true,
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          if (_localError != null) ...[
            Text(_localError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          if (actionState.errorMessage != null) ...[
            Text(actionState.errorMessage!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          PrimaryButton(
            label: 'Salvar',
            onPressed: _submit,
            isLoading: actionState.isLoading,
            disabled: !_isFormValid(),
          ),
        ],
      ),
    );
  }
}
