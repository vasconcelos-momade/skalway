String pdvFormatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String pdvFormatMoney(num value) {
  final amount = value.toDouble();
  final hasDecimals = amount != amount.truncateToDouble();
  return '${amount.toStringAsFixed(hasDecimals ? 2 : 0)} MT';
}

/// Título do produto no catálogo PDV: nome comercial - dosagem - forma.
String pdvProductDisplayTitle({
  required String nomeComercial,
  String? dosagem,
  String? forma,
}) {
  final parts = <String>[
    nomeComercial,
    if (dosagem != null && dosagem.trim().isNotEmpty) dosagem.trim(),
    if (forma != null && forma.trim().isNotEmpty) forma.trim(),
  ];
  return parts.join(' - ');
}
