import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/form_clear_link.dart';
import '../../../core/ui/components/primary_button.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/brazilian_phone_formatter.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  String? _localError;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _localError = null;
    });
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
      setState(
        () => _localError = 'Telefone invalido. Use o formato (XX) XXXXX-XXXX.',
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          firstName: firstName,
          lastName: _lastNameController.text.trim(),
          phone: phone,
        );

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.errorMessage == null) {
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentUserDisplayNameProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
      context.pop();
    } else {
      setState(() => _localError = state.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus dados cadastrais')),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => const Center(child: Text('Erro ao carregar dados.')),
        data: (profile) {
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _firstNameController.text = profile.firstName;
              _lastNameController.text = profile.lastName;
              _phoneController.text = profile.phone;
              _emailController.text = profile.email;
            });
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_localError != null) ...[
                        Text(
                          _localError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                        label: 'Telefone',
                        isRequired: true,
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [BrazilianPhoneInputFormatter()],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Email',
                        isRequired: true,
                        controller: _emailController,
                        readOnly: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
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
                      onPressed: (authState.isLoading || !_isFormValid())
                          ? null
                          : _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 8),
                    FormClearLink(onTap: _clear),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
