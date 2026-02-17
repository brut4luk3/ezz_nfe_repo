import 'package:flutter/services.dart';

/// Formatter para valor monetário: cada dígito digitado representa centavos.
/// Valor inicial 0.00. Ao digitar: 1 → 0.01, 10 → 0.10, 100 → 1.00, 1000 → 10.00.
/// O usuário não precisa digitar o ponto decimal.
class CurrencyDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cents = digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    final text = (cents / 100).toStringAsFixed(2);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formata valor monetário brasileiro: R$ 1.234,56
/// Aceita dígitos, vírgula ou ponto como separador decimal.
/// O valor é tratado como decimal (ex: 69.90 = R$ 69,90).
class BrazilianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final cents = _parseToCentsFromInput(raw);
    if (cents == null || cents < 0) {
      return oldValue;
    }
    final text = formatFromCents(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Parse durante digitação: aceita "69.90", "69,90" (decimal) ou "6990" (já em centavos).
  static int? _parseToCentsFromInput(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'R\$|\s'), '');
    if (cleaned.isEmpty) return 0;
    final hasDecimal = cleaned.contains(',') || cleaned.contains('.');
    if (hasDecimal) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      String normalized;
      if (lastComma > lastDot) {
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = cleaned.replaceAll(',', '');
      }
      final value = double.tryParse(normalized);
      if (value == null || value < 0) return null;
      return (value * 100).round();
    }
    final value = int.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return value;
  }

  /// Formata valor em centavos para exibição: R$ 1.234,56
  static String formatFromCents(int cents) {
    if (cents == 0) return 'R\$ 0,00';
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    final intStr = reais.toString();
    String formatted = '';
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) formatted += '.';
      formatted += intStr[i];
    }
    return 'R\$ $formatted,${centavos.toString().padLeft(2, '0')}';
  }

  /// Parse do texto formatado para centavos.
  /// Aceita: "R$ 55,90", "55,90", "55.90" (decimal) ou "5590" (centavos).
  static int? parseToCents(String text) {
    final cleaned = text.replaceAll(RegExp(r'R\$|\s'), '').trim();
    if (cleaned.isEmpty) return null;
    final hasDecimal = cleaned.contains(',') || cleaned.contains('.');
    if (hasDecimal) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      String normalized;
      if (lastComma > lastDot) {
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = cleaned.replaceAll(',', '');
      }
      final value = double.tryParse(normalized);
      if (value == null || value < 0) return null;
      return (value * 100).round();
    }
    final value = int.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return value;
  }
}
