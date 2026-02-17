import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field compartilhado com suporte a:
/// - [prefixIcon] e [suffixIcon] (ex: lupa para busca, eye para senha)
/// - [textInputAction] configurável (send, next, search, etc.)
/// - [onChanged] para filtros em tempo real
/// - [obscureText] com toggle de visibilidade automático
class AppTextField extends StatefulWidget {
  final String label;
  /// Quando true, exibe * ao lado da label (campo obrigatório).
  final bool isRequired;
  /// Quando true, exibe " (opcional)" após a label.
  final bool isOptional;
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
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.isOptional = false,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.readOnly = false,
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

  String _buildLabelText() {
    if (widget.isRequired) return '${widget.label} *';
    if (widget.isOptional) return '${widget.label} (opcional)';
    return widget.label;
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
      readOnly: widget.readOnly,
      obscureText: _obscureText,
      textInputAction: effectiveAction,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onSubmitted: handleSubmitted,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: _buildLabelText(),
        border: const OutlineInputBorder(),
        prefixIcon: widget.prefixIcon,
        prefixText: widget.prefixText,
        suffixIcon: _buildSuffixIcon(),
      ),
    );
  }
}
