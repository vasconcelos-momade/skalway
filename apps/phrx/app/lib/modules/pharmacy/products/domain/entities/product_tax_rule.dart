/// Regra fiscal associada ao produto (espelho do backend).
class ProductTaxRule {
  const ProductTaxRule({
    this.id,
    required this.tipo,
    required this.taxa,
    this.codigo,
    this.nome,
    this.descricao,
    this.ativo = true,
  });

  final String? id;
  final String tipo;
  /// Taxa em percentual (ex.: 16) ou decimal (0.16).
  final double taxa;
  final String? codigo;
  final String? nome;
  final String? descricao;
  final bool ativo;

  bool get isExempt =>
      tipo == 'IVA_ISENTO' ||
      tipo == 'NAO_TRIBUTAVEL' ||
      taxa <= 0;

  double get taxaPercentual => taxa <= 1 ? taxa * 100 : taxa;

  String get displayLabel {
    final base = (nome != null && nome!.trim().isNotEmpty) ? nome!.trim() : tipo;
    return '$base (${taxaPercentual.toStringAsFixed(taxaPercentual % 1 == 0 ? 0 : 2)}%)';
  }
}
