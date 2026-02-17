import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Diálogo simples para adicionar um item com um único campo (nome).
Future<T?> showSimpleAddDialog<T>({
  required BuildContext context,
  required String title,
  required String label,
  required Future<T?> Function(String name) onSubmit,
}) async {
  return showDialog<T>(
    context: context,
    builder: (context) => _SimpleAddDialog<T>(
      title: title,
      label: label,
      onSubmit: onSubmit,
    ),
  );
}

class _SimpleAddDialog<T> extends StatefulWidget {
  final String title;
  final String label;
  final Future<T?> Function(String name) onSubmit;

  const _SimpleAddDialog({
    required this.title,
    required this.label,
    required this.onSubmit,
  });

  @override
  State<_SimpleAddDialog<T>> createState() => _SimpleAddDialogState<T>();
}

class _SimpleAddDialogState<T> extends State<_SimpleAddDialog<T>> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = '${widget.label} é obrigatório.';
        _isLoading = false;
      });
      return;
    }
    final result = await widget.onSubmit(name);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() => _error = 'Não foi possível salvar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          AppTextField(
            label: widget.label,
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ) : const Text('Salvar'),
        ),
      ],
    );
  }
}
