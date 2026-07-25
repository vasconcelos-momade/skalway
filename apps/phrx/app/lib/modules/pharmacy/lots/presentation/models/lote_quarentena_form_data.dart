class LoteQuarentenaFormData {
  const LoteQuarentenaFormData({
    required this.quantidade,
    required this.motivo,
    this.documentoReferencia,
  });

  final num quantidade;
  final String motivo;
  final String? documentoReferencia;
}
