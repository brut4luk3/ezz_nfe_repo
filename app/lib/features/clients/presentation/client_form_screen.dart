import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/brazilian_cpf_formatter.dart';
import '../../../core/utils/brazilian_phone_formatter.dart';
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
  final _origemController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _origemFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _localError;
  bool _indicacao = false;
  String? _indicadorClientId;
  bool _inadimplente = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _origemController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cpfFocus.dispose();
    _origemFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _setValues(Client client) {
    _nameController.text = client.name;
    _phoneController.text = client.phone;
    _cpfController.text = client.cpf ?? '';
    _origemController.text = client.origem ?? '';
    _notesController.text = client.notes ?? '';
    _indicacao = client.indicacao;
    _indicadorClientId = client.indicadorClientId;
    _inadimplente = client.inadimplente;
  }

  bool _isPhoneValid() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty && _isPhoneValid();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      setState(() => _localError = 'Nome e obrigatorio.');
      return;
    }
    if (!_isPhoneValid()) {
      setState(() =>
          _localError = 'Telefone invalido. Use o formato (XX) XXXXX-XXXX.');
      return;
    }
    final client = Client(
      id: widget.clientId ?? '',
      name: name,
      phone: phone,
      cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      origem:
          _origemController.text.trim().isEmpty ? null : _origemController.text.trim(),
      indicacao: _indicacao,
      indicadorClientId: _indicacao ? _indicadorClientId : null,
      inadimplente: _inadimplente,
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
    final clientsAsync = ref.watch(clientsListProvider);
    final otherClients = clientsAsync.valueOrNull
            ?.where((c) => c.id != widget.clientId)
            .toList() ??
        [];

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
            nextFocusNode: _phoneFocus,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Telefone (ex: (47) 99999-9999)',
            isRequired: true,
            controller: _phoneController,
            focusNode: _phoneFocus,
            nextFocusNode: _cpfFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [BrazilianPhoneInputFormatter()],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'CPF',
            isOptional: true,
            controller: _cpfController,
            focusNode: _cpfFocus,
            nextFocusNode: _origemFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [BrazilianCpfInputFormatter()],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Origem',
            isOptional: true,
            controller: _origemController,
            focusNode: _origemFocus,
            nextFocusNode: _notesFocus,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool>(
            value: _indicacao,
            decoration: const InputDecoration(
              labelText: 'Indicação (opcional)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: false, child: Text('Não')),
              DropdownMenuItem(value: true, child: Text('Sim')),
            ],
            onChanged: (value) => setState(() {
              _indicacao = value ?? false;
              if (!_indicacao) _indicadorClientId = null;
            }),
          ),
          if (_indicacao) ...[
            const SizedBox(height: 12),
            otherClients.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Cadastre outro cliente para selecionar como indicador.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _indicadorClientId,
                    decoration: const InputDecoration(
                      labelText: 'Cliente indicador (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: otherClients
                        .map<DropdownMenuItem<String>>(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _indicadorClientId = value),
                  ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<bool>(
            value: _inadimplente,
            decoration: const InputDecoration(
              labelText: 'Inadimplente (opcional)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: false, child: Text('Não')),
              DropdownMenuItem(value: true, child: Text('Sim')),
            ],
            onChanged: (value) =>
                setState(() => _inadimplente = value ?? false),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Observacoes',
            isOptional: true,
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
            disabled: !_isFormValid(),
          ),
        ],
      ),
    );
  }
}
