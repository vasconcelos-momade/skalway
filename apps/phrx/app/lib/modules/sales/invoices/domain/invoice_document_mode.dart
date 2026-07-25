/// Regras de documento fiscal: FR → 80mm térmico; FT → PDF A4.
library;

const kInvoiceTipoFr = 'FR';
const kInvoiceTipoFt = 'FT';
const kDocumentModeThermal80mm = 'thermal_80mm';
const kDocumentModePdfA4 = 'pdf_a4';

bool isThermalReceiptTipo(String? tipo) {
  return (tipo ?? '').trim().toUpperCase() == kInvoiceTipoFr;
}

bool isPdfA4Tipo(String? tipo) {
  return !isThermalReceiptTipo(tipo);
}

String resolveDocumentMode({
  String? tipo,
  String? documentMode,
}) {
  final mode = (documentMode ?? '').trim().toLowerCase();
  if (mode == kDocumentModeThermal80mm || mode == kDocumentModePdfA4) {
    return mode;
  }
  return isThermalReceiptTipo(tipo)
      ? kDocumentModeThermal80mm
      : kDocumentModePdfA4;
}

/// Extrai texto legível de bytes ESC/POS (para preview 80mm).
String decodeEscPosPreview(List<int> bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    if (b == 0x0a) {
      buffer.writeln();
      continue;
    }
    if (b == 0x0d) continue;
    if (b >= 0x20 && b <= 0x7e) {
      buffer.writeCharCode(b);
    }
  }
  return buffer.toString().trim();
}
