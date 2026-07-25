import '../../../../core/contracts/pagination_response.dart';

enum PurchaseSuggestionOriginFilter { todas, automatica, manual }

class PurchaseSuggestionDashboard {
  const PurchaseSuggestionDashboard({
    this.produtosAbaixoMinimo = 0,
    this.produtosSemStock = 0,
    this.valorEstimadoCompra = 0,
    this.quantidadeTotalSugerida = 0,
    this.fornecedoresEnvolvidos = 0,
  });

  final int produtosAbaixoMinimo;
  final int produtosSemStock;
  final num valorEstimadoCompra;
  final num quantidadeTotalSugerida;
  final int fornecedoresEnvolvidos;

  factory PurchaseSuggestionDashboard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PurchaseSuggestionDashboard();
    return PurchaseSuggestionDashboard(
      produtosAbaixoMinimo: json['produtosAbaixoMinimo'] as int? ?? 0,
      produtosSemStock: json['produtosSemStock'] as int? ?? 0,
      valorEstimadoCompra: json['valorEstimadoCompra'] as num? ?? 0,
      quantidadeTotalSugerida: json['quantidadeTotalSugerida'] as num? ?? 0,
      fornecedoresEnvolvidos: json['fornecedoresEnvolvidos'] as int? ?? 0,
    );
  }
}

class PurchaseSuggestionItem {
  const PurchaseSuggestionItem({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.categoriaNome,
    required this.fornecedorNome,
    required this.consumoMedioDiario,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    required this.coberturaDias,
    required this.quantidadeSugerida,
    required this.ultimoPreco,
    required this.valorEstimado,
    required this.unidade,
    required this.origem,
    this.fornecedorId,
    this.observacao,
  });

  final String id;
  final String produtoId;
  final String produtoNome;
  final String categoriaNome;
  final String? fornecedorId;
  final String fornecedorNome;
  final num consumoMedioDiario;
  final num estoqueAtual;
  final num estoqueMinimo;
  final int coberturaDias;
  final num quantidadeSugerida;
  final num ultimoPreco;
  final num valorEstimado;
  final String unidade;
  final String origem;
  final String? observacao;

  bool get isManual => origem == 'MANUAL';

  String get origemLabel => isManual ? 'Manual' : 'Automática';

  static num _readNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  factory PurchaseSuggestionItem.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestionItem(
      id: json['id']?.toString() ?? '',
      produtoId: json['produtoId']?.toString() ?? '',
      produtoNome: json['produtoNome']?.toString() ?? '—',
      categoriaNome: json['categoriaNome']?.toString() ?? '—',
      fornecedorId: json['fornecedorId']?.toString(),
      fornecedorNome: json['fornecedorNome']?.toString() ?? 'Sem fornecedor',
      consumoMedioDiario: _readNum(json['consumoMedioDiario']),
      estoqueAtual: _readNum(json['estoqueAtual']),
      estoqueMinimo: _readNum(json['estoqueMinimo']),
      coberturaDias: json['coberturaDias'] as int? ?? 30,
      quantidadeSugerida: _readNum(json['quantidadeSugerida']),
      ultimoPreco: _readNum(json['ultimoPreco']),
      valorEstimado: _readNum(json['valorEstimado']),
      unidade: json['unidade']?.toString() ?? 'un',
      origem: json['origem']?.toString() ?? 'AUTOMATICA',
      observacao: json['observacao']?.toString(),
    );
  }
}

class PurchaseSuggestionGroup {
  const PurchaseSuggestionGroup({
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.items,
  });

  final String? fornecedorId;
  final String fornecedorNome;
  final List<PurchaseSuggestionItem> items;

  factory PurchaseSuggestionGroup.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestionGroup(
      fornecedorId: json['fornecedorId']?.toString(),
      fornecedorNome: json['fornecedorNome']?.toString() ?? 'Sem fornecedor',
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PurchaseSuggestionItem.fromJson)
          .toList(),
    );
  }
}

class PurchaseSuggestionsListResponse {
  const PurchaseSuggestionsListResponse({
    required this.items,
    required this.groupedByFornecedor,
    required this.dashboard,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
  });

  final List<PurchaseSuggestionItem> items;
  final List<PurchaseSuggestionGroup> groupedByFornecedor;
  final PurchaseSuggestionDashboard dashboard;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;

  factory PurchaseSuggestionsListResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestionsListResponse(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PurchaseSuggestionItem.fromJson)
          .toList(),
      groupedByFornecedor:
          (json['groupedByFornecedor'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(PurchaseSuggestionGroup.fromJson)
              .toList(),
      dashboard: PurchaseSuggestionDashboard.fromJson(
        json['dashboard'] as Map<String, dynamic>?,
      ),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? PaginationDefaults.pageSize,
      hasMore: json['hasMore'] as bool? ?? false,
      totalCount: json['totalCount'] as int? ?? json['totalItens'] as int?,
    );
  }
}
