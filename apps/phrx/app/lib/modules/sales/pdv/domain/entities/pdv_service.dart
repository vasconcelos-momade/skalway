class PdvService {
  const PdvService({
    required this.id,
    required this.nome,
    required this.preco,
    this.tipoServicoClinico,
  });

  final String id;
  final String nome;
  final double preco;
  final String? tipoServicoClinico;
}
