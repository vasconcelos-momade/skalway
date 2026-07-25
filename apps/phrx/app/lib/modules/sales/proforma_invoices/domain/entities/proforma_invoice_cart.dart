import 'proforma_invoice_cart_line.dart';

class ProformaInvoiceCart {
  const ProformaInvoiceCart({this.lines = const <ProformaInvoiceCartLine>[]});

  final List<ProformaInvoiceCartLine> lines;

  int get itemCount => lines.length;

  double get unitsCount =>
      lines.fold<double>(0, (sum, line) => sum + line.quantidade);

  double get subtotal =>
      lines.fold<double>(0, (sum, line) => sum + line.subtotal);

  double get descontoTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.descontoValor);

  double get ivaTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.valorIva);

  double get total => lines.fold<double>(0, (sum, line) => sum + line.total);

  bool get isEmpty => lines.isEmpty;

  ProformaInvoiceCart copyWith({List<ProformaInvoiceCartLine>? lines}) {
    return ProformaInvoiceCart(lines: lines ?? this.lines);
  }
}
