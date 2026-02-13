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
        FocusScope.of(context).nextFocus();
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
