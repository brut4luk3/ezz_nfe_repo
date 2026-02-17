import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/brazilian_date_formatter.dart';

/// Campo de data/hora no formato brasileiro DD/MM/AAAA (e HH:mm quando [includeTime]).
/// Exibe como TextField com formatação e ícone de calendário à direita.
/// Permite digitação manual ou seleção via calendário.
class AppDateField extends StatefulWidget {
  final String label;
  final bool isRequired;
  final bool isOptional;
  final DateTime? value;
  final void Function(DateTime?)? onChanged;
  /// Quando true, exibe também HH:mm após a data.
  final bool includeTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const AppDateField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.isOptional = false,
    this.value,
    this.onChanged,
    this.includeTime = false,
    this.firstDate,
    this.lastDate,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null
          ? formatBrazilianDate(widget.value!, includeTime: widget.includeTime)
          : '',
    );
  }

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = widget.value != null
          ? formatBrazilianDate(widget.value!, includeTime: widget.includeTime)
          : '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _buildLabelText() {
    if (widget.isRequired) return '${widget.label} *';
    if (widget.isOptional) return '${widget.label} (opcional)';
    return widget.label;
  }

  Future<void> _openDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now.add(const Duration(days: 365)),
      firstDate: widget.firstDate ?? now,
      lastDate: widget.lastDate ?? now.add(const Duration(days: 365 * 10)),
    );
    if (picked == null || !mounted) return;
    DateTime result = picked;
    if (widget.includeTime) {
      final timePicker = await showTimePicker(
        context: context,
        initialTime: widget.value != null
            ? TimeOfDay(
                hour: widget.value!.hour,
                minute: widget.value!.minute,
              )
            : const TimeOfDay(hour: 0, minute: 0),
      );
      if (timePicker != null) {
        result = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicker.hour,
          timePicker.minute,
        );
      }
    }
    _controller.text =
        formatBrazilianDate(result, includeTime: widget.includeTime);
    widget.onChanged?.call(result);
  }

  void _onClear() {
    _controller.clear();
    widget.onChanged?.call(null);
  }

  void _onTextChanged(String text) {
    final parsed = parseBrazilianDate(text);
    if (parsed != null || text.isEmpty) {
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      readOnly: false,
      keyboardType: TextInputType.datetime,
      onChanged: _onTextChanged,
      inputFormatters: [
        BrazilianDateInputFormatter(includeTime: widget.includeTime),
        LengthLimitingTextInputFormatter(widget.includeTime ? 16 : 10),
      ],
      decoration: InputDecoration(
        labelText: _buildLabelText(),
        border: const OutlineInputBorder(),
        hintText: widget.includeTime ? 'DD/MM/AAAA HH:mm' : 'DD/MM/AAAA',
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _onClear,
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _openDatePicker,
            ),
          ],
        ),
      ),
    );
  }
}
