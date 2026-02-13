import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
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
                  ref.read(themeControllerProvider.notifier).setThemeMode(
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              const SizedBox(height: 4),
              Text('Unlocked: ${authState.biometricUnlocked}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => _onLogout(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
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
