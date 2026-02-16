import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/clients/data/client_model.dart';
import '../../../features/clients/presentation/clients_providers.dart';
import '../../utils/brazilian_phone_formatter.dart';
import 'app_text_field.dart';

/// Form compacto para adicionar cliente dentro do SelectDialog.
/// Apenas campos obrigatórios: Nome, Telefone.
class SelectAddClientForm extends ConsumerStatefulWidget {
  final void Function(Future<String?> Function() submit) registerSubmit;

  const SelectAddClientForm({
    super.key,
    required this.registerSubmit,
  });

  @override
  ConsumerState<SelectAddClientForm> createState() => _SelectAddClientFormState();
}

class _SelectAddClientFormState extends ConsumerState<SelectAddClientForm> {
  final _nomeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nomeFocus = FocusNode();
  final _phoneFocus = FocusNode();
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
    _nomeController.dispose();
    _phoneController.dispose();
    _nomeFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool _isPhoneValid() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  Future<String?> _submit() async {
    setState(() => _error = null);
    final nome = _nomeController.text.trim();
    final phone = _phoneController.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Nome e obrigatorio.');
      return null;
    }
    if (!_isPhoneValid()) {
      setState(() =>
          _error = 'Telefone invalido. Use o formato (XX) XXXXX-XXXX.');
      return null;
    }
    final firstName = nome;
    final client = Client(
      id: '',
      firstName: firstName,
      lastName: '',
      phone: phone,
      addedViaSelectDialog: true,
    );
    final controller = ref.read(clientsControllerProvider.notifier);
    final id = await controller.create(client);
    if (id != null) ref.invalidate(clientsListProvider);
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
          controller: _nomeController,
          focusNode: _nomeFocus,
          nextFocusNode: _phoneFocus,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Telefone',
          isRequired: true,
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [BrazilianPhoneInputFormatter()],
        ),
      ],
    );
  }
}
