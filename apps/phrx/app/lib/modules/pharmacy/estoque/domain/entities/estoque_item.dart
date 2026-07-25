class EstoqueItem {
  const EstoqueItem({
    required this.id,
    required this.produtoId,
    this.produtoNomeComercial,
    this.produtoNomeGenerico,
    this.produtoDosagem,
    this.produtoFormaFarmaceutica,
    this.produtoBarcode,
    this.categoriaId,
    this.categoriaNome,
    this.fornecedorId,
    this.fornecedorNome,
    required this.numeroLote,
    this.dataValidade,
    this.diasRestantes,
    this.indicadorValidade,
    this.indicadorStock,
    this.quantidadeDisponivel = 0,
    this.quantidadeTotal = 0,
    this.quantidadeInicial = 0,
    this.quantidadeQuarentena = 0,
    this.quantidadeIncinerada = 0,
    this.precoCompra = 0,
    this.precoVenda,
    this.estadoSanitario,
    this.estadoSanitarioEfetivo,
    this.acoesPermitidas = const [],
    this.disponibilidade,
    this.ultimaAtualizacao,
    this.estoqueMinimo = 0,
  });

  final String id;
  final String produtoId;
  final String? produtoNomeComercial;
  final String? produtoNomeGenerico;
  final String? produtoDosagem;
  final String? produtoFormaFarmaceutica;
  final String? produtoBarcode;
  final String? categoriaId;
  final String? categoriaNome;
  final String? fornecedorId;
  final String? fornecedorNome;
  final String numeroLote;
  final DateTime? dataValidade;
  final int? diasRestantes;
  final String? indicadorValidade;
  final String? indicadorStock;
  final num quantidadeDisponivel;
  final num quantidadeTotal;
  final num quantidadeInicial;
  final num quantidadeQuarentena;
  final num quantidadeIncinerada;
  final num precoCompra;
  final num? precoVenda;
  final String? estadoSanitario;
  final String? estadoSanitarioEfetivo;
  final List<String> acoesPermitidas;
  final String? disponibilidade;
  final DateTime? ultimaAtualizacao;
  final num estoqueMinimo;

  bool permiteAcaoSanitaria(String tipo) => acoesPermitidas.contains(tipo);

  Map<String, dynamic> toActionMap() => <String, dynamic>{
        'id': id,
        'produtoId': produtoId,
        'produtoNomeComercial': produtoNomeComercial,
        'produtoNome': produtoNomeComercial,
        'produtoDosagem': produtoDosagem,
        'produtoFormaFarmaceutica': produtoFormaFarmaceutica,
        'numeroLote': numeroLote,
        'quantidadeDisponivel': quantidadeDisponivel,
        'quantidadeTotal': quantidadeTotal,
        'quantidadeQuarentena': quantidadeQuarentena,
        'quantidadeIncinerada': quantidadeIncinerada,
        'estadoSanitario': estadoSanitario,
        'estadoSanitarioEfetivo': estadoSanitarioEfetivo,
        'acoesPermitidas': acoesPermitidas,
        'disponibilidade': disponibilidade,
        'dataValidade': dataValidade?.toIso8601String(),
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
      };
}

/// Ex.: `Aminofilina 500mg Cápsulas`
String formatEstoqueProdutoLabel({
  String? nomeComercial,
  String? dosagem,
  String? forma,
}) {
  final parts = <String>[
    if ((nomeComercial ?? '').trim().isNotEmpty) nomeComercial!.trim(),
    if ((dosagem ?? '').trim().isNotEmpty) dosagem!.trim(),
    if ((forma ?? '').trim().isNotEmpty) forma!.trim(),
  ];
  return parts.isEmpty ? '—' : parts.join(' ');
}

extension EstoqueItemDisplayX on EstoqueItem {
  String get produtoDisplayLabel => formatEstoqueProdutoLabel(
        nomeComercial: produtoNomeComercial,
        dosagem: produtoDosagem,
        forma: produtoFormaFarmaceutica,
      );
}
