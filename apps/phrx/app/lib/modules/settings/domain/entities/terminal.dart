class TerminalDetalhe {
  const TerminalDetalhe({
    required this.id,
    required this.codigo,
    required this.nome,
    this.localizacao,
    this.ativo = true,
    this.caixaId,
  });

  final String id;
  final String codigo;
  final String nome;
  final String? localizacao;
  final bool ativo;
  final String? caixaId;
}
