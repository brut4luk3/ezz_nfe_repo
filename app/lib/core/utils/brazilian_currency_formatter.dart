import 'package:flutter/services.dart';

/// Formata valor monetário brasileiro: R$ 1.234,56
/// Aceita dígitos e uma vírgula ou ponto como separador decimal.
/// Ex: digitar 49,90 ou 49.90 exibe R$ 49,90
class BrazilianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final cents = int.tryParse(digits) ?? 0;
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    final intStr = reais.toString();
    String formatted = '';
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) formatted += '.';
      formatted += intStr[i];
    }
    final text = 'R\$ $formatted,${centavos.toString().padLeft(2, '0')}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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
  static int? parseToCents(String text) {
    final cleaned = text.replaceAll('R\$', '').replaceAll('.', '').trim();
    final normalized = cleaned.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }
}
