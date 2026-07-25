class EstoqueDashboard {
  const EstoqueDashboard({
    required this.produtosEmStock,
    required this.lotesAtivos,
    required this.produtosSemStock,
    required this.lotesAExpirar,
    required this.lotesExpirados,
    required this.valorTotalInventario,
    this.lotesEmRecall = 0,
    this.lotesEmQuarentena = 0,
    this.lotesIncinerados = 0,
  });

  final int produtosEmStock;
  final int lotesAtivos;
  final int produtosSemStock;
  final int lotesAExpirar;
  final int lotesExpirados;
  final num valorTotalInventario;
  final int lotesEmRecall;
  final int lotesEmQuarentena;
  final int lotesIncinerados;
}
