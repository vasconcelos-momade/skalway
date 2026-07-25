class Category {
  const Category({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    this.productCount = 0,
  });

  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int productCount;
}
