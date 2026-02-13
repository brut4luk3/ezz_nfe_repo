import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.keyboardType,
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
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
    );
  }
}
