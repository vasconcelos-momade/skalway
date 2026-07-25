import 'pdv_cart_line.dart';

/// Carrinho PDV sincronizado com a fatura rascunho no backend.
class PdvCart {
  const PdvCart({
    this.draftFaturaId,
    this.idempotencyKey,
    this.lines = const <PdvCartLine>[],
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.taxLabel = 'IVA',
    this.requiresPatientDetails = false,
  });

  final String? draftFaturaId;
  final String? idempotencyKey;
  final List<PdvCartLine> lines;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String taxLabel;
  final bool requiresPatientDetails;

  bool get isEmpty => lines.isEmpty;
}
