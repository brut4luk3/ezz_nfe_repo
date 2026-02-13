import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/utils/brazilian_phone_formatter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String? _localError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _localError = null);
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _localError = 'Preencha todos os campos obrigatorios.');
      return;
    }
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10) {
      setState(() => _localError = 'Telefone invalido. Use o formato (XX) XXXXX-XXXX.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'As senhas nao coincidem.');
      return;
    }

    ref.read(authControllerProvider.notifier).register(
          email,
          password,
          fullName: fullName,
          phone: phone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Criar conta',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use seu email e senha.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Nome completo',
          controller: _fullNameController,
          focusNode: _fullNameFocus,
          nextFocusNode: _phoneFocus,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Telefone (ex: (47) 99999-9999)',
          controller: _phoneController,
          focusNode: _phoneFocus,
          nextFocusNode: _emailFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [BrazilianPhoneInputFormatter()],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          focusNode: _emailFocus,
          nextFocusNode: _passwordFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Senha',
          controller: _passwordController,
          focusNode: _passwordFocus,
          nextFocusNode: _confirmFocus,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Confirmar senha',
          controller: _confirmController,
          focusNode: _confirmFocus,
          obscureText: true,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        if (_localError != null) ...[
          Text(
            _localError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        if (authState.errorMessage != null) ...[
          Text(
            authState.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        PrimaryButton(
          label: 'Criar conta',
          onPressed: _submit,
          isLoading: authState.isLoading,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: authState.isLoading ? null : () => context.go('/login'),
          child: const Text('Voltar para login'),
        ),
      ],
    );
  }
}
