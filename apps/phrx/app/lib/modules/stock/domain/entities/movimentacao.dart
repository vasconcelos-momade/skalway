enum MovimentacaoTipo {
  entrada,
  compra,
  saida,
  ajuste,
  devolucao,
  quarentena,
  incineracao,
}

extension MovimentacaoTipoX on MovimentacaoTipo {
  String get apiValue {
    switch (this) {
      case MovimentacaoTipo.entrada:
        return 'ENTRADA';
      case MovimentacaoTipo.compra:
        return 'COMPRA';
      case MovimentacaoTipo.saida:
        return 'SAIDA';
      case MovimentacaoTipo.ajuste:
        return 'AJUSTE';
      case MovimentacaoTipo.devolucao:
        return 'DEVOLUCAO';
      case MovimentacaoTipo.quarentena:
        return 'QUARENTENA';
      case MovimentacaoTipo.incineracao:
        return 'INCINERACAO';
    }
  }

  static MovimentacaoTipo? fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'ENTRADA':
        return MovimentacaoTipo.entrada;
      case 'COMPRA':
        return MovimentacaoTipo.compra;
      case 'SAIDA':
        return MovimentacaoTipo.saida;
      case 'AJUSTE':
        return MovimentacaoTipo.ajuste;
      case 'DEVOLUCAO':
        return MovimentacaoTipo.devolucao;
      case 'QUARENTENA':
        return MovimentacaoTipo.quarentena;
      case 'INCINERACAO':
        return MovimentacaoTipo.incineracao;
      default:
        return null;
    }
  }
}

enum MovimentacaoQuickFilter { none, today, week, month }

class MovimentacaoFilterOption {
  const MovimentacaoFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class MovimentacaoAggregate {
  const MovimentacaoAggregate({required this.count, required this.quantidade});

  final int count;
  final double quantidade;
}

class MovimentacaoOverview {
  const MovimentacaoOverview({
    required this.totalMovimentos,
    required this.entradas,
    required this.saidas,
    required this.ajustes,
    required this.devolucoes,
    required this.quarentenas,
    required this.incineracoes,
  });

  final int totalMovimentos;
  final MovimentacaoAggregate entradas;
  final MovimentacaoAggregate saidas;
  final MovimentacaoAggregate ajustes;
  final MovimentacaoAggregate devolucoes;
  final MovimentacaoAggregate quarentenas;
  final MovimentacaoAggregate incineracoes;

  static const empty = MovimentacaoOverview(
    totalMovimentos: 0,
    entradas: MovimentacaoAggregate(count: 0, quantidade: 0),
    saidas: MovimentacaoAggregate(count: 0, quantidade: 0),
    ajustes: MovimentacaoAggregate(count: 0, quantidade: 0),
    devolucoes: MovimentacaoAggregate(count: 0, quantidade: 0),
    quarentenas: MovimentacaoAggregate(count: 0, quantidade: 0),
    incineracoes: MovimentacaoAggregate(count: 0, quantidade: 0),
  );
}

class MovimentacaoFilters {
  const MovimentacaoFilters({
    this.tipos = const <MovimentacaoFilterOption>[],
    this.origens = const <MovimentacaoFilterOption>[],
  });

  final List<MovimentacaoFilterOption> tipos;
  final List<MovimentacaoFilterOption> origens;

  static const empty = MovimentacaoFilters();
}

class MovimentacaoProdutoResumo {
  const MovimentacaoProdutoResumo({
    required this.id,
    required this.nome,
    this.barcode,
  });

  final String id;
  final String nome;
  final String? barcode;
}

class MovimentacaoLoteResumo {
  const MovimentacaoLoteResumo({required this.id, required this.numeroLote});

  final String id;
  final String numeroLote;
}

class MovimentacaoUserResumo {
  const MovimentacaoUserResumo({required this.id, required this.nome});

  final String id;
  final String nome;
}

class Movimentacao {
  const Movimentacao({
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
  final MovimentacaoTipo? tipo;
  final String tipoLabel;
  final double quantidade;
  final double estoqueAnterior;
  final double estoqueFinal;
  final String? origem;
  final String origemLabel;
  final String? documentoReferencia;
  final String? observacoes;
  final DateTime createdAt;
  final MovimentacaoProdutoResumo? produto;
  final MovimentacaoLoteResumo? lote;
  final MovimentacaoUserResumo? user;
}

class MovimentacaoQuery {
  const MovimentacaoQuery({
    this.search = '',
    this.tipo,
    this.origem,
    this.dataInicio,
    this.dataFim,
    this.quickFilter = MovimentacaoQuickFilter.none,
    this.page = 1,
    this.pageSize = 10,
  });

  final String search;
  final String? tipo;
  final String? origem;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final MovimentacaoQuickFilter quickFilter;
  final int page;
  final int pageSize;

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      tipo != null ||
      origem != null ||
      dataInicio != null ||
      dataFim != null ||
      quickFilter != MovimentacaoQuickFilter.none;

  MovimentacaoQuery copyWith({
    String? search,
    String? tipo,
    String? origem,
    DateTime? dataInicio,
    DateTime? dataFim,
    MovimentacaoQuickFilter? quickFilter,
    int? page,
    int? pageSize,
    bool clearTipo = false,
    bool clearOrigem = false,
    bool clearDateRange = false,
  }) {
    return MovimentacaoQuery(
      search: search ?? this.search,
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      origem: clearOrigem ? null : (origem ?? this.origem),
      dataInicio: clearDateRange ? null : (dataInicio ?? this.dataInicio),
      dataFim: clearDateRange ? null : (dataFim ?? this.dataFim),
      quickFilter: quickFilter ?? this.quickFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class MovimentacoesPageResult {
  const MovimentacoesPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.overview,
    required this.filters,
  });

  final List<Movimentacao> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final MovimentacaoOverview overview;
  final MovimentacaoFilters filters;
}
