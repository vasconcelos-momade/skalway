class CaixaSessao {
  const CaixaSessao({
    required this.id,
    required this.caixaId,
    this.terminalId,
    required this.userId,
    required this.abertura,
    required this.sistema,
    this.contado,
    this.diferenca,
    this.observacaoFecho,
    this.fechadoPorId,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.deletedAt,
  });

  final String id;
  final String caixaId;
  final String? terminalId;
  final String userId;
  final double abertura;
  final double sistema;
  final double? contado;
  final double? diferenca;
  final String? observacaoFecho;
  final String? fechadoPorId;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime? deletedAt;
}
