class SalesHistoryDashboard {
  const SalesHistoryDashboard({
    this.totalVendas = 0,
    this.receitaTotal = 0,
    this.ticketMedio = 0,
    this.topProdutos = const [],
  });

  final int totalVendas;
  final double receitaTotal;
  final double ticketMedio;
  final List<SalesTopProduct> topProdutos;

  factory SalesHistoryDashboard.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final rawTop = json['topProdutos'];
    return SalesHistoryDashboard(
      totalVendas: asInt(json['totalVendas']),
      receitaTotal: asDouble(json['receitaTotal']),
      ticketMedio: asDouble(json['ticketMedio']),
      topProdutos: rawTop is List
          ? rawTop
              .whereType<Map<String, dynamic>>()
              .map(SalesTopProduct.fromJson)
              .toList()
          : const [],
    );
  }
}

class SalesTopProduct {
  const SalesTopProduct({
    required this.nome,
    this.quantidade = 0,
    this.receita = 0,
  });

  final String nome;
  final double quantidade;
  final double receita;

  factory SalesTopProduct.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    return SalesTopProduct(
      nome: json['nome']?.toString() ?? '—',
      quantidade: asDouble(json['quantidade']),
      receita: asDouble(json['receita']),
    );
  }
}

class SalesHistoryQuery {
  const SalesHistoryQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.status,
    this.dateFrom,
    this.dateTo,
    this.quickFilter = SalesHistoryQuickFilter.none,
  });

  final int page;
  final int pageSize;
  final String search;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final SalesHistoryQuickFilter quickFilter;

  SalesHistoryQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    SalesHistoryQuickFilter? quickFilter,
    bool clearStatus = false,
    bool clearDateRange = false,
  }) {
    return SalesHistoryQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      quickFilter: quickFilter ?? this.quickFilter,
    );
  }

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      status != null ||
      dateFrom != null ||
      dateTo != null ||
      quickFilter != SalesHistoryQuickFilter.none;
}

enum SalesHistoryQuickFilter { none, today, week, month }
