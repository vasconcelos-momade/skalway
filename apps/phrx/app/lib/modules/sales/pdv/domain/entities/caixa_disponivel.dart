class CaixaDisponivel {
  const CaixaDisponivel({
    required this.caixaId,
    required this.terminalId,
    required this.terminalCodigo,
    required this.terminalNome,
    this.localizacao,
  });

  final String caixaId;
  final String terminalId;
  final String terminalCodigo;
  final String terminalNome;
  final String? localizacao;

  String get displayName {
    final base = '$terminalCodigo • $terminalNome';
    if (localizacao == null || localizacao!.trim().isEmpty) {
      return base;
    }
    return '$base • ${localizacao!.trim()}';
  }
}
