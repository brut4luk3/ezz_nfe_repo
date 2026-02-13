import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _localError = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Preencha email e senha.');
      return;
    }
    ref.read(authControllerProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Login',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Entre com seu email e senha.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Senha',
          controller: _passwordController,
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
          label: 'Entrar',
          onPressed: _submit,
          isLoading: authState.isLoading,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed:
              authState.isLoading ? null : () => context.go('/register'),
          child: const Text('Criar conta'),
        ),
      ],
    );
  }
}
