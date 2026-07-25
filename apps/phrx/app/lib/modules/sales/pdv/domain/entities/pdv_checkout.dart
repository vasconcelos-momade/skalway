enum PdvPaymentMethod {
  dinheiro,
  mpesa,
  emola,
  cartao,
}

class PdvCheckoutPatient {
  const PdvCheckoutPatient({
    this.nome,
    this.idade,
    this.nid,
    this.prescritor,
    this.unidadeSanitaria,
  });

  final String? nome;
  final int? idade;
  final String? nid;
  final String? prescritor;
  final String? unidadeSanitaria;
}

class PdvCheckoutLine {
  const PdvCheckoutLine({
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.precoUnit,
    required this.total,
    this.produtoId,
    this.servicoId,
  });

  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final String descricao;
  final int quantidade;
  final double precoUnit;
  final double total;
}

class PdvCheckoutResult {
  const PdvCheckoutResult({
    required this.id,
    required this.numero,
    required this.estado,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    this.tipo = 'FR',
    this.documentMode = 'thermal_80mm',
    this.troco = 0,
    this.items = const [],
    required this.cartReset,
    required this.nextCartIdempotencyKey,
  });

  final String id;
  final String numero;
  final String tipo;
  final String documentMode;
  final String estado;
  final double subtotal;
  final double ivaTotal;
  final double total;
  final double troco;
  final List<PdvCheckoutLine> items;
  final bool cartReset;
  final String nextCartIdempotencyKey;

  bool get isThermalReceipt => tipo.toUpperCase() == 'FR';
}
