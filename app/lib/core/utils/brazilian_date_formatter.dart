import 'package:flutter/services.dart';

/// Formata data brasileira: DD/MM/AAAA (e opcionalmente HH:mm).
/// Aceita apenas dígitos; insere '/' automaticamente.
class BrazilianDateInputFormatter extends TextInputFormatter {
  final bool includeTime;

  BrazilianDateInputFormatter({this.includeTime = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final maxLen = includeTime ? 12 : 8;
    if (digits.length > maxLen) {
      return oldValue;
    }
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) formatted += '/';
      if (includeTime && i == 8) formatted += ' ';
      if (includeTime && i == 10) formatted += ':';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Parse DD/MM/AAAA ou DD/MM/AAAA HH:mm para DateTime.
DateTime? parseBrazilianDate(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) return null;
  final day = int.tryParse(digits.substring(0, 2));
  final month = int.tryParse(digits.substring(2, 4));
  final year = int.tryParse(digits.substring(4, 8));
  if (day == null || month == null || year == null) return null;
  if (day < 1 || day > 31) return null;
  if (month < 1 || month > 12) return null;
  if (year < 1900 || year > 2100) return null;
  int hour = 0, minute = 0;
  if (digits.length >= 12) {
    hour = int.tryParse(digits.substring(8, 10)) ?? 0;
    minute = int.tryParse(digits.substring(10, 12)) ?? 0;
    if (hour > 23) hour = 23;
    if (minute > 59) minute = 59;
  }
  try {
    return DateTime(year, month, day, hour, minute);
  } catch (_) {
    return null;
  }
}

/// Formata DateTime para DD/MM/AAAA ou DD/MM/AAAA HH:mm.
String formatBrazilianDate(DateTime date, {bool includeTime = false}) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  if (!includeTime) return '$d/$m/$y';
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}
