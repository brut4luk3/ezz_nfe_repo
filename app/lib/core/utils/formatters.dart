String formatCurrency(int cents) {
  final value = cents / 100.0;
  return 'R\$ ${value.toStringAsFixed(2)}';
}

/// Formata valor em reais (double).
String formatCurrencyValue(double value) {
  return 'R\$ ${value.toStringAsFixed(2)}';
}

String formatDateTime(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

/// Data e hora no formato brasileiro: DD/MM/AAAA - HH:MM
String formatDateTimeBr(DateTime dateTime) {
  final d = dateTime.day.toString().padLeft(2, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final y = dateTime.year.toString().padLeft(4, '0');
  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  return '$d/$m/$y - $hh:$mm';
}
