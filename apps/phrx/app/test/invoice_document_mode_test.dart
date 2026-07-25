import 'package:flutter_test/flutter_test.dart';
import 'package:phrx/modules/sales/invoices/domain/invoice_document_mode.dart';

void main() {
  test('FR is thermal 80mm', () {
    expect(isThermalReceiptTipo('FR'), isTrue);
    expect(resolveDocumentMode(tipo: 'FR'), kDocumentModeThermal80mm);
  });

  test('FT is pdf A4', () {
    expect(isPdfA4Tipo('FT'), isTrue);
    expect(resolveDocumentMode(tipo: 'FT'), kDocumentModePdfA4);
  });

  test('decodeEscPosPreview keeps printable text', () {
    final bytes = <int>[0x1b, 0x40, ...'HELLO'.codeUnits, 0x0a, ...'WORLD'.codeUnits];
    expect(decodeEscPosPreview(bytes), contains('HELLO'));
    expect(decodeEscPosPreview(bytes), contains('WORLD'));
  });
}
