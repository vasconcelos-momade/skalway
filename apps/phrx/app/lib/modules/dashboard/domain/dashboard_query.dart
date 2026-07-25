import 'package:flutter/material.dart';

enum DashboardPeriodPreset {
  today,
  yesterday,
  last7days,
  last30days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

@immutable
class DashboardQuery {
  const DashboardQuery({
    this.period = DashboardPeriodPreset.last30days,
    this.from,
    this.to,
    this.days = 30,
    this.search = '',
    this.categoriaId,
    this.produtoId,
    this.clienteId,
    this.fornecedorId,
    this.estado,
    this.metodoPagamento,
    this.tipoMovimentacao,
    this.sortBy,
    this.sortDir = 'desc',
  });

  final DashboardPeriodPreset period;
  final DateTime? from;
  final DateTime? to;
  final int days;
  final String search;
  final String? categoriaId;
  final String? produtoId;
  final String? clienteId;
  final String? fornecedorId;
  final String? estado;
  final String? metodoPagamento;
  final String? tipoMovimentacao;
  final String? sortBy;
  final String sortDir;

  bool get hasActiveFilters =>
      period != DashboardPeriodPreset.last30days ||
      from != null ||
      to != null ||
      search.trim().isNotEmpty ||
      categoriaId != null ||
      produtoId != null ||
      clienteId != null ||
      fornecedorId != null ||
      estado != null ||
      metodoPagamento != null ||
      tipoMovimentacao != null;

  DashboardQuery copyWith({
    DashboardPeriodPreset? period,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
    int? days,
    String? search,
    String? categoriaId,
    String? produtoId,
    String? clienteId,
    String? fornecedorId,
    String? estado,
    String? metodoPagamento,
    String? tipoMovimentacao,
    String? sortBy,
    String? sortDir,
    bool clearCategoriaId = false,
    bool clearProdutoId = false,
    bool clearClienteId = false,
    bool clearFornecedorId = false,
    bool clearEstado = false,
    bool clearMetodoPagamento = false,
    bool clearTipoMovimentacao = false,
    bool clearSortBy = false,
  }) {
    return DashboardQuery(
      period: period ?? this.period,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      days: days ?? this.days,
      search: search ?? this.search,
      categoriaId: clearCategoriaId ? null : (categoriaId ?? this.categoriaId),
      produtoId: clearProdutoId ? null : (produtoId ?? this.produtoId),
      clienteId: clearClienteId ? null : (clienteId ?? this.clienteId),
      fornecedorId: clearFornecedorId ? null : (fornecedorId ?? this.fornecedorId),
      estado: clearEstado ? null : (estado ?? this.estado),
      metodoPagamento:
          clearMetodoPagamento ? null : (metodoPagamento ?? this.metodoPagamento),
      tipoMovimentacao:
          clearTipoMovimentacao ? null : (tipoMovimentacao ?? this.tipoMovimentacao),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortDir: sortDir ?? this.sortDir,
    );
  }

  Map<String, dynamic> toParams({bool includePagination = false, int? page, int? pageSize}) {
    final params = <String, dynamic>{};

    if (period == DashboardPeriodPreset.custom && from != null && to != null) {
      params['from'] = _isoDate(from!);
      params['to'] = _isoDate(to!);
    } else if (period != DashboardPeriodPreset.last30days) {
      params['period'] = _periodKey(period);
    } else {
      params['days'] = days;
    }

    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if (categoriaId != null) params['categoriaId'] = categoriaId;
    if (produtoId != null) params['produtoId'] = produtoId;
    if (clienteId != null) params['clienteId'] = clienteId;
    if (fornecedorId != null) params['fornecedorId'] = fornecedorId;
    if (estado != null) params['estado'] = estado;
    if (metodoPagamento != null) params['metodoPagamento'] = metodoPagamento;
    if (tipoMovimentacao != null) params['tipoMovimentacao'] = tipoMovimentacao;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortDir.isNotEmpty) params['sortDir'] = sortDir;

    if (includePagination) {
      if (page != null) params['page'] = page;
      if (pageSize != null) params['pageSize'] = pageSize;
    }

    return params;
  }

  String get reloadKey => Object.hashAll([
        period,
        from,
        to,
        days,
        search,
        categoriaId,
        produtoId,
        clienteId,
        fornecedorId,
        estado,
        metodoPagamento,
        tipoMovimentacao,
        sortBy,
        sortDir,
      ]).toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardQuery &&
          period == other.period &&
          from == other.from &&
          to == other.to &&
          days == other.days &&
          search == other.search &&
          categoriaId == other.categoriaId &&
          produtoId == other.produtoId &&
          clienteId == other.clienteId &&
          fornecedorId == other.fornecedorId &&
          estado == other.estado &&
          metodoPagamento == other.metodoPagamento &&
          tipoMovimentacao == other.tipoMovimentacao &&
          sortBy == other.sortBy &&
          sortDir == other.sortDir;

  @override
  int get hashCode => Object.hash(
        period,
        from,
        to,
        days,
        search,
        categoriaId,
        produtoId,
        clienteId,
        fornecedorId,
        estado,
        metodoPagamento,
        tipoMovimentacao,
        sortBy,
        sortDir,
      );

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _periodKey(DashboardPeriodPreset preset) {
    return switch (preset) {
      DashboardPeriodPreset.today => 'today',
      DashboardPeriodPreset.yesterday => 'yesterday',
      DashboardPeriodPreset.last7days => 'last7days',
      DashboardPeriodPreset.last30days => 'last30days',
      DashboardPeriodPreset.thisMonth => 'thisMonth',
      DashboardPeriodPreset.lastMonth => 'lastMonth',
      DashboardPeriodPreset.thisYear => 'thisYear',
      DashboardPeriodPreset.custom => 'custom',
    };
  }
}
