import 'package:flutter/material.dart';

/// Text field compartilhado com suporte a:
/// - [prefixIcon] e [suffixIcon] (ex: lupa para busca, eye para senha)
/// - [textInputAction] configurável (send, next, search, etc.)
/// - [onChanged] para filtros em tempo real
/// - [obscureText] com toggle de visibilidade automático
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  /// When [textInputAction] is [TextInputAction.next], requesting focus on this
  /// node keeps keyboard visible on Android (avoids HIDE_SOFT_INPUT race).
  final FocusNode? nextFocusNode;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAction = widget.textInputAction ??
        (widget.onSubmitted != null ? TextInputAction.send : TextInputAction.next);

    void handleSubmitted(String value) {
      if (effectiveAction == TextInputAction.next) {
        if (widget.nextFocusNode != null) {
          // Defer to let Android process unfocus before we request focus;
          // avoids HIDE_SOFT_INPUT closing keyboard before next field opens it.
          final next = widget.nextFocusNode!;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) next.requestFocus();
          });
        } else {
          final current = FocusManager.instance.primaryFocus;
          if (current != null) {
            current.nextFocus();
          } else {
            FocusScope.of(context).nextFocus();
          }
        }
      }
      widget.onSubmitted?.call(value);
    }

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      textInputAction: effectiveAction,
      keyboardType: widget.keyboardType,
      onSubmitted: handleSubmitted,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(),
      ),
    );
  }
}
