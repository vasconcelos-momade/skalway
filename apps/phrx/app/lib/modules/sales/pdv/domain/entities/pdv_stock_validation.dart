class PdvStockValidation {
  const PdvStockValidation({
    required this.canAdd,
    required this.maximumAllowedQuantity,
    required this.mensagem,
  });

  final bool canAdd;
  final int maximumAllowedQuantity;
  final String mensagem;
}
