import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/ui/components/primary_button.dart';

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Desbloquear',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use a biometria para continuar.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (authState.errorMessage != null) ...[
          Text(
            authState.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: 'Desbloquear com biometria',
          onPressed: () =>
              ref.read(authControllerProvider.notifier).unlockWithBiometrics(),
          isLoading: authState.isLoading,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: authState.isLoading
              ? null
              : () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}
