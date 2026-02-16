import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_text_field.dart';
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
class SelectFormField<T> extends ConsumerWidget {
  final String label;
  final List<SelectOption<T>> items;
  final bool multiple;
  final List<T> value;
  final void Function(List<T>) onChanged;
  final String searchHint;
  final bool isRequired;
  final bool isOptional;
  final String Function(T)? valueToLabel;
  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    void Function(Future<T?> Function() submit) registerSubmit,
  )? buildAddForm;

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
    this.buildAddForm,
  });

  String _labelText() {
    if (isRequired) return '$label *';
    if (isOptional) return '$label (opcional)';
    return label;
  }

  String _displayText() {
    if (value.isEmpty) return '';
    String labelFor(T v) {
      try {
        return items.firstWhere((o) => o.value == v).label;
      } catch (_) {
        return valueToLabel?.call(v) ?? v.toString();
      }
    }
    return value.map(labelFor).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final result = await showSelectDialog<T>(
          context: context,
          ref: ref,
          items: items,
          multiple: multiple,
          initialSelection: value,
          searchHint: searchHint,
          buildAddForm: buildAddForm,
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
/// - [buildAddForm]: quando fornecido, exibe "Adicionar" e permite criar item.
/// - Ao confirmar, retorna a lista de valores selecionados.
/// - Ao fechar (X), retorna null.
Future<List<T>?> showSelectDialog<T>({
  required BuildContext context,
  required WidgetRef ref,
  required List<SelectOption<T>> items,
  required bool multiple,
  List<T>? initialSelection,
  String searchHint = 'Buscar',
  Widget Function(
    BuildContext context,
    WidgetRef ref,
    void Function(Future<T?> Function() submit) registerSubmit,
  )? buildAddForm,
}) async {
  return showDialog<List<T>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SelectDialog<T>(
      ref: ref,
      items: items,
      multiple: multiple,
      initialSelection: initialSelection ?? [],
      searchHint: searchHint,
      buildAddForm: buildAddForm,
    ),
  );
}

class _SelectDialog<T> extends StatefulWidget {
  final WidgetRef ref;
  final List<SelectOption<T>> items;
  final bool multiple;
  final List<T> initialSelection;
  final String searchHint;
  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    void Function(Future<T?> Function() submit) registerSubmit,
  )? buildAddForm;

  const _SelectDialog({
    required this.ref,
    required this.items,
    required this.multiple,
    required this.initialSelection,
    required this.searchHint,
    this.buildAddForm,
  });

  @override
  State<_SelectDialog<T>> createState() => _SelectDialogState<T>();
}

class _SelectDialogState<T> extends State<_SelectDialog<T>> {
  late List<T> _selected;
  final _searchController = TextEditingController();
  String _query = '';
  bool _isAddMode = false;
  bool _isSaving = false;
  Future<T?> Function()? _submitFn;

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

  void _enterAddMode() {
    setState(() {
      _isAddMode = true;
      _submitFn = null;
    });
  }

  void _exitAddMode() {
    setState(() {
      _isAddMode = false;
      _submitFn = null;
    });
  }

  void _registerSubmit(Future<T?> Function() fn) {
    _submitFn = fn;
  }

  Future<void> _saveNew() async {
    final fn = _submitFn;
    if (fn == null) return;
    setState(() => _isSaving = true);
    final newId = await fn();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (newId == null) return;
    setState(() {
      if (widget.multiple) {
        _selected.add(newId);
      } else {
        _selected = [newId];
      }
    });
    if (!mounted) return;
    Navigator.of(context).pop(_selected);
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
                  if (_isAddMode)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      onPressed: _exitAddMode,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  Text(
                    _isAddMode ? 'Adicionar' : 'Selecione',
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
                child: _isAddMode
                    ? SingleChildScrollView(
                        child: widget.buildAddForm!(
                          context,
                          widget.ref,
                          _registerSubmit,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: widget.searchHint,
                            controller: _searchController,
                            prefixIcon: const Icon(Icons.search),
                            textInputAction: TextInputAction.search,
                          ),
                          if (widget.buildAddForm != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _enterAddMode,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Adicionar',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                    icon: _isAddMode ? Icons.save : null,
                    label: _isAddMode ? 'Salvar' : 'Confirmar',
                    onPressed: _isAddMode ? _saveNew : _confirm,
                    isLoading: _isAddMode && _isSaving,
                    disabled: _isAddMode && _isSaving,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isAddMode ? _exitAddMode : _clearSelection,
                    child: Text(
                      _isAddMode ? 'Voltar' : 'Limpar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
