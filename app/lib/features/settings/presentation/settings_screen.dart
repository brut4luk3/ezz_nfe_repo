import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Meus dados cadastrais'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/profile'),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadastros auxiliares',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Tipos de produto'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/products/types'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sell_outlined),
                      title: const Text('Marcas de produto'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/products/brands'),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aparência',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Modo escuro'),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Biometria'),
                    const SizedBox(height: 8),
                    if (authState.errorMessage != null) ...[
                      Text(
                        authState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Desbloqueio por biometria'),
                      value: authState.biometricEnabled,
                      onChanged: authState.isLoading
                          ? null
                          : (value) => ref
                                .read(authControllerProvider.notifier)
                                .setBiometricEnabled(value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => _onLogout(context, ref),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Sair da conta',
      message: 'Tem certeza que deseja sair? Você precisará entrar novamente.',
      confirmLabel: 'Sair',
      cancelLabel: 'Cancelar',
    );
    if (!ok || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}
