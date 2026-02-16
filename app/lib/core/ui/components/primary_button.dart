import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  /// Quando true, o botao fica desabilitado (ex: formulario incompleto).
  final bool disabled;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (isLoading || disabled) ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  )
                : Text(label),
      ),
    );
  }
}
