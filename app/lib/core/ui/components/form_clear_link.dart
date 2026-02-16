import 'package:flutter/material.dart';

/// Texto clicável "Limpar" para formulários. Padrão: negrito, sem sublinhado.
class FormClearLink extends StatelessWidget {
  final VoidCallback onTap;

  const FormClearLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Limpar',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
