class FornecedorResumo {
  const FornecedorResumo({
    required this.id,
    required this.nome,
    this.nuit,
    this.telefone,
    this.email,
  });

  final String id;
  final String nome;
  final String? nuit;
  final String? telefone;
  final String? email;
}

class FornecedorDetalhe {
  const FornecedorDetalhe({
    required this.id,
    required this.nome,
    this.tipo,
    this.nuit,
    this.email,
    this.telefone,
    this.telefoneAlt,
    this.endereco,
    this.cidade,
    this.provincia,
    this.pais,
    this.contatoNome,
    this.observacoes,
    this.ativo = true,
  });

  final String id;
  final String nome;
  final String? tipo;
  final String? nuit;
  final String? email;
  final String? telefone;
  final String? telefoneAlt;
  final String? endereco;
  final String? cidade;
  final String? provincia;
  final String? pais;
  final String? contatoNome;
  final String? observacoes;
  final bool ativo;
}
