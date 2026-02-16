import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/components/select_add_client_form.dart';
import '../../../core/ui/components/select_dialog.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _origemController = TextEditingController();
  final _notesController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _origemFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _localError;
  bool _indicacao = false;
  bool _userHasCleared = false;
  String? _indicadorClientId;
  bool _inadimplente = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _origemController.dispose();
    _notesController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _cpfFocus.dispose();
    _origemFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _userHasCleared = true;
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _cpfController.clear();
      _origemController.clear();
      _notesController.clear();
      _indicacao = false;
      _indicadorClientId = null;
      _inadimplente = false;
      _localError = null;
    });
  }

  void _setValues(Client client) {
    _firstNameController.text = client.firstName;
    _lastNameController.text = client.lastName;
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
    return _firstNameController.text.trim().isNotEmpty && _isPhoneValid();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final firstName = _firstNameController.text.trim();
    final phone = _phoneController.text.trim();
    if (firstName.isEmpty) {
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
      firstName: firstName,
      lastName: _lastNameController.text.trim(),
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
            if (client != null &&
                _firstNameController.text.isEmpty &&
                !_userHasCleared) {
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
            controller: _firstNameController,
            focusNode: _firstNameFocus,
            nextFocusNode: _lastNameFocus,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Sobrenome',
            isOptional: true,
            controller: _lastNameController,
            focusNode: _lastNameFocus,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Indicação (opcional)'),
            value: _indicacao,
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (value) => setState(() {
              _indicacao = value;
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
                : SelectFormField<String>(
                    label: 'Cliente indicador',
                    items: otherClients
                        .map((c) => SelectOption<String>(value: c.id, label: c.name))
                        .toList(),
                    multiple: false,
                    value: _indicadorClientId != null
                        ? [_indicadorClientId!]
                        : [],
                    onChanged: (v) =>
                        setState(() => _indicadorClientId = v.isNotEmpty ? v.first : null),
                    searchHint: 'Buscar cliente',
                    isOptional: true,
                    buildAddForm: (context, ref, registerSubmit) =>
                        SelectAddClientForm(registerSubmit: registerSubmit),
                  ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inadimplente (opcional)'),
            value: _inadimplente,
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (value) => setState(() => _inadimplente = value),
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
