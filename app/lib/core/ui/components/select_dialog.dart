import 'package:flutter/material.dart';

import 'app_text_field.dart';
import 'form_clear_link.dart';
import 'primary_button.dart';

/// Opção selecionável para uso no [SelectDialog].
class SelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SelectOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

/// Campo de formulário que exibe a seleção e abre [showSelectDialog] ao tocar.
class SelectFormField<T> extends StatelessWidget {
  final String label;
  final List<SelectOption<T>> items;
  final bool multiple;
  final List<T> value;
  final void Function(List<T>) onChanged;
  final String searchHint;
  final bool isRequired;
  final bool isOptional;
  final String Function(T)? valueToLabel;

  const SelectFormField({
    super.key,
    required this.label,
    required this.items,
    required this.multiple,
    required this.value,
    required this.onChanged,
    this.searchHint = 'Buscar',
    this.isRequired = false,
    this.isOptional = false,
    this.valueToLabel,
  });

  String _labelText() {
    if (isRequired) return '$label *';
    if (isOptional) return '$label (opcional)';
    return label;
  }

  String _displayText() {
    if (value.isEmpty) return '';
    final getLabel = valueToLabel ??
        (v) => items.firstWhere((o) => o.value == v, orElse: () => items.first).label;
    return value.map(getLabel).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showSelectDialog<T>(
          context: context,
          items: items,
          multiple: multiple,
          initialSelection: value,
          searchHint: searchHint,
        );
        if (result != null) onChanged(result);
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _labelText(),
          hintText: value.isEmpty ? 'Selecione...' : null,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _displayText(),
          style: TextStyle(
            color: _displayText().isEmpty
                ? Theme.of(context).hintColor
                : null,
          ),
        ),
      ),
    );
  }
}

/// Dialog modular para seleção de um ou múltiplos itens.
///
/// - [multiple]: true = múltipla seleção (itens permanecem ativos);
///   false = seleção única (outros itens ficam disabled ao selecionar).
/// - Ao confirmar, retorna a lista de valores selecionados.
/// - Ao fechar (X), retorna null.
Future<List<T>?> showSelectDialog<T>({
  required BuildContext context,
  required List<SelectOption<T>> items,
  required bool multiple,
  List<T>? initialSelection,
  String searchHint = 'Buscar',
}) async {
  return showDialog<List<T>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SelectDialog<T>(
      items: items,
      multiple: multiple,
      initialSelection: initialSelection ?? [],
      searchHint: searchHint,
    ),
  );
}

class _SelectDialog<T> extends StatefulWidget {
  final List<SelectOption<T>> items;
  final bool multiple;
  final List<T> initialSelection;
  final String searchHint;

  const _SelectDialog({
    required this.items,
    required this.multiple,
    required this.initialSelection,
    required this.searchHint,
  });

  @override
  State<_SelectDialog<T>> createState() => _SelectDialogState<T>();
}

class _SelectDialogState<T> extends State<_SelectDialog<T>> {
  late List<T> _selected;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final validValues = widget.items.map((o) => o.value).toSet();
    _selected = widget.initialSelection
        .where((v) => validValues.contains(v))
        .toList();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SelectOption<T>> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((o) => o.label.toLowerCase().contains(_query))
        .toList();
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  void _toggle(T value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        if (widget.multiple) {
          _selected.add(value);
        } else {
          _selected = [value];
        }
      }
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selected);
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: SizedBox(
          height: 560,
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'Selecione',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                    onPressed: _close,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: widget.searchHint,
                      controller: _searchController,
                      prefixIcon: const Icon(Icons.search),
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum item encontrado.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final opt = filtered[index];
                                final isSelected = _selected.contains(opt.value);
                                final isDisabled = !widget.multiple &&
                                    _selected.isNotEmpty &&
                                    !isSelected;

                                return ListTile(
                                  title: Text(opt.label),
                                  subtitle: opt.subtitle != null
                                      ? Text(opt.subtitle!)
                                      : null,
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                  enabled: !isDisabled,
                                  onTap: isDisabled
                                      ? null
                                      : () => _toggle(opt.value),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Confirmar',
                    onPressed: _confirm,
                  ),
                  const SizedBox(height: 8),
                  FormClearLink(onTap: _clearSelection),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
