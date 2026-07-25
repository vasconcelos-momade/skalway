import '../../domain/entities/movimentacao.dart';

class MovimentacaoFilterOptionModel {
  const MovimentacaoFilterOptionModel({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory MovimentacaoFilterOptionModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoFilterOptionModel(
      value: json['value']?.toString() ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  MovimentacaoFilterOption toEntity() {
    return MovimentacaoFilterOption(value: value, label: label);
  }
}

class MovimentacaoAggregateModel {
  const MovimentacaoAggregateModel({
    required this.count,
    required this.quantidade,
  });

  final int count;
  final double quantidade;

  factory MovimentacaoAggregateModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoAggregateModel(
      count: _toInt(json['count']),
      quantidade: _toDouble(json['quantidade']),
    );
  }

  MovimentacaoAggregate toEntity() {
    return MovimentacaoAggregate(count: count, quantidade: quantidade);
  }
}

class MovimentacaoOverviewModel {
  const MovimentacaoOverviewModel({
    required this.totalMovimentos,
    required this.entradas,
    required this.saidas,
    required this.ajustes,
    required this.devolucoes,
    required this.quarentenas,
    required this.incineracoes,
  });

  final int totalMovimentos;
  final MovimentacaoAggregateModel entradas;
  final MovimentacaoAggregateModel saidas;
  final MovimentacaoAggregateModel ajustes;
  final MovimentacaoAggregateModel devolucoes;
  final MovimentacaoAggregateModel quarentenas;
  final MovimentacaoAggregateModel incineracoes;

  factory MovimentacaoOverviewModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoOverviewModel(
      totalMovimentos: _toInt(json['totalMovimentos']),
      entradas: MovimentacaoAggregateModel.fromJson(
        _asMap(json['entradas']) ?? const <String, dynamic>{},
      ),
      saidas: MovimentacaoAggregateModel.fromJson(
        _asMap(json['saidas']) ?? const <String, dynamic>{},
      ),
      ajustes: MovimentacaoAggregateModel.fromJson(
        _asMap(json['ajustes']) ?? const <String, dynamic>{},
      ),
      devolucoes: MovimentacaoAggregateModel.fromJson(
        _asMap(json['devolucoes']) ?? const <String, dynamic>{},
      ),
      quarentenas: MovimentacaoAggregateModel.fromJson(
        _asMap(json['quarentenas']) ?? const <String, dynamic>{},
      ),
      incineracoes: MovimentacaoAggregateModel.fromJson(
        _asMap(json['incineracoes']) ?? const <String, dynamic>{},
      ),
    );
  }

  MovimentacaoOverview toEntity() {
    return MovimentacaoOverview(
      totalMovimentos: totalMovimentos,
      entradas: entradas.toEntity(),
      saidas: saidas.toEntity(),
      ajustes: ajustes.toEntity(),
      devolucoes: devolucoes.toEntity(),
      quarentenas: quarentenas.toEntity(),
      incineracoes: incineracoes.toEntity(),
    );
  }
}

class MovimentacaoFiltersModel {
  const MovimentacaoFiltersModel({required this.tipos, required this.origens});

  final List<MovimentacaoFilterOptionModel> tipos;
  final List<MovimentacaoFilterOptionModel> origens;

  factory MovimentacaoFiltersModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoFiltersModel(
      tipos: _parseOptions(json['tipos']),
      origens: _parseOptions(json['origens']),
    );
  }

  MovimentacaoFilters toEntity() {
    return MovimentacaoFilters(
      tipos: tipos.map((item) => item.toEntity()).toList(growable: false),
      origens: origens.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}

class MovimentacaoProdutoResumoModel {
  const MovimentacaoProdutoResumoModel({
    required this.id,
    required this.nome,
    this.barcode,
  });

  final String id;
  final String nome;
  final String? barcode;

  factory MovimentacaoProdutoResumoModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoProdutoResumoModel(
      id: json['id'].toString(),
      nome: json['nomeComercial'] as String? ?? json['nome'] as String? ?? '',
      barcode: json['barcode'] as String?,
    );
  }

  MovimentacaoProdutoResumo toEntity() {
    return MovimentacaoProdutoResumo(id: id, nome: nome, barcode: barcode);
  }
}

class MovimentacaoLoteResumoModel {
  const MovimentacaoLoteResumoModel({
    required this.id,
    required this.numeroLote,
  });

  final String id;
  final String numeroLote;

  factory MovimentacaoLoteResumoModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoLoteResumoModel(
      id: json['id'].toString(),
      numeroLote: json['numeroLote'] as String? ?? '',
    );
  }

  MovimentacaoLoteResumo toEntity() {
    return MovimentacaoLoteResumo(id: id, numeroLote: numeroLote);
  }
}

class MovimentacaoUserResumoModel {
  const MovimentacaoUserResumoModel({required this.id, required this.nome});

  final String id;
  final String nome;

  factory MovimentacaoUserResumoModel.fromJson(Map<String, dynamic> json) {
    return MovimentacaoUserResumoModel(
      id: json['id'].toString(),
      nome: json['nome'] as String? ?? '',
    );
  }

  MovimentacaoUserResumo toEntity() {
    return MovimentacaoUserResumo(id: id, nome: nome);
  }
}

class MovimentacaoModel {
  const MovimentacaoModel({
    required this.id,
    required this.tipo,
    required this.tipoLabel,
    required this.quantidade,
    required this.estoqueAnterior,
    required this.estoqueFinal,
    this.origem,
    required this.origemLabel,
    this.documentoReferencia,
    this.observacoes,
    required this.createdAt,
    this.produto,
    this.lote,
    this.user,
  });

  final String id;
  final String? tipo;
  final String tipoLabel;
  final double quantidade;
  final double estoqueAnterior;
  final double estoqueFinal;
  final String? origem;
  final String origemLabel;
  final String? documentoReferencia;
  final String? observacoes;
  final DateTime createdAt;
  final MovimentacaoProdutoResumoModel? produto;
  final MovimentacaoLoteResumoModel? lote;
  final MovimentacaoUserResumoModel? user;

  factory MovimentacaoModel.fromJson(Map<String, dynamic> json) {
    final produtoJson = _asMap(json['produto']);
    final loteJson = _asMap(json['lote']);
    final userJson = _asMap(json['user']);

    return MovimentacaoModel(
      id: json['id'].toString(),
      tipo: json['tipo'] as String?,
      tipoLabel: json['tipoLabel'] as String? ?? json['tipo'] as String? ?? '',
      quantidade: _toDouble(json['quantidade']),
      estoqueAnterior: _toDouble(json['estoqueAnterior']),
      estoqueFinal: _toDouble(json['estoqueFinal']),
      origem: json['origem'] as String?,
      origemLabel: json['origemLabel'] as String? ?? 'Sem origem',
      documentoReferencia: json['documentoReferencia'] as String?,
      observacoes: json['observacoes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      produto: produtoJson == null
          ? null
          : MovimentacaoProdutoResumoModel.fromJson(produtoJson),
      lote: loteJson == null
          ? null
          : MovimentacaoLoteResumoModel.fromJson(loteJson),
      user: userJson == null
          ? null
          : MovimentacaoUserResumoModel.fromJson(userJson),
    );
  }

  Movimentacao toEntity() {
    return Movimentacao(
      id: id,
      tipo: MovimentacaoTipoX.fromApi(tipo),
      tipoLabel: tipoLabel,
      quantidade: quantidade,
      estoqueAnterior: estoqueAnterior,
      estoqueFinal: estoqueFinal,
      origem: origem,
      origemLabel: origemLabel,
      documentoReferencia: documentoReferencia,
      observacoes: observacoes,
      createdAt: createdAt,
      produto: produto?.toEntity(),
      lote: lote?.toEntity(),
      user: user?.toEntity(),
    );
  }
}

class MovimentacoesPageResultModel {
  const MovimentacoesPageResultModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.overview,
    required this.filters,
  });

  final List<MovimentacaoModel> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final MovimentacaoOverviewModel overview;
  final MovimentacaoFiltersModel filters;

  factory MovimentacoesPageResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(MovimentacaoModel.fromJson)
              .toList()
        : const <MovimentacaoModel>[];

    return MovimentacoesPageResultModel(
      items: items,
      page: _toInt(json['page'], fallback: 1),
      pageSize: _toInt(json['pageSize'], fallback: 20),
      hasMore: json['hasMore'] == true,
      overview: MovimentacaoOverviewModel.fromJson(
        _asMap(json['overview']) ?? const <String, dynamic>{},
      ),
      filters: MovimentacaoFiltersModel.fromJson(
        _asMap(json['filters']) ?? const <String, dynamic>{},
      ),
    );
  }

  MovimentacoesPageResult toEntity() {
    return MovimentacoesPageResult(
      items: items.map((item) => item.toEntity()).toList(growable: false),
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
      overview: overview.toEntity(),
      filters: filters.toEntity(),
    );
  }
}

List<MovimentacaoFilterOptionModel> _parseOptions(dynamic raw) {
  if (raw is! List) {
    return const <MovimentacaoFilterOptionModel>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(MovimentacaoFilterOptionModel.fromJson)
      .toList(growable: false);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
