/// Rascunho de fatura POS devolvido pela API após adicionar itens.
class PdvDraftSale {
  const PdvDraftSale({
    required this.id,
    required this.numero,
    required this.estado,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
  });

  final String id;
  final String numero;
  final String estado;
  final double subtotal;
  final double ivaTotal;
  final double total;
}
