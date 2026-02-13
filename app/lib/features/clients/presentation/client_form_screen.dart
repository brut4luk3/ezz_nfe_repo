import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../data/client_model.dart';
import 'clients_providers.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;
  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cpfFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _setValues(Client client) {
    _nameController.text = client.name;
    _phoneController.text = client.phone ?? '';
    _cpfController.text = client.cpf ?? '';
    _notesController.text = client.notes ?? '';
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _localError = 'Nome e obrigatorio.');
      return;
    }
    final client = Client(
      id: widget.clientId ?? '',
      name: name,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(clientsControllerProvider.notifier);
    if (widget.clientId == null) {
      await controller.create(client);
    } else {
      await controller.update(widget.clientId!, client);
    }

    if (!mounted) return;
    final state = ref.read(clientsControllerProvider);
    if (state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(clientsControllerProvider);

    if (widget.clientId != null) {
      final clientAsync = ref.watch(clientByIdProvider(widget.clientId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Editar cliente')),
        body: clientAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (client) {
            if (client != null && _nameController.text.isEmpty) {
              _setValues(client);
            }
            return _form(actionState);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo cliente')),
      body: _form(actionState),
    );
  }

  Widget _form(ClientsActionState actionState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _nameController,
            focusNode: _nameFocus,
            nextFocusNode: _phoneFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Telefone',
            controller: _phoneController,
            focusNode: _phoneFocus,
            nextFocusNode: _cpfFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'CPF',
            controller: _cpfController,
            focusNode: _cpfFocus,
            nextFocusNode: _notesFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Observacoes',
            controller: _notesController,
            focusNode: _notesFocus,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          if (_localError != null) ...[
            Text(
              _localError!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
          ],
          if (actionState.errorMessage != null) ...[
            Text(
              actionState.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
          ],
          PrimaryButton(
            label: 'Salvar',
            onPressed: _submit,
            isLoading: actionState.isLoading,
          ),
        ],
      ),
    );
  }
}
