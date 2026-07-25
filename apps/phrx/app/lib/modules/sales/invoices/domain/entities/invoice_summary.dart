class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.numero,
    required this.serie,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    required this.troco,
    required this.estado,
    required this.tipoPagamento,
    required this.createdAt,
    this.tipo = 'FT',
    this.documentMode,
    this.cancelledAt,
    this.valorRecebido,
    this.cliente,
    this.terminal,
    this.user,
    this.itemCount = 0,
    this.paymentCount = 0,
  });

  final String id;
  final String numero;
  final String? serie;
  final String tipo;
  final String? documentMode;
  final double subtotal;
  final double ivaTotal;
  final double total;
  final double troco;
  final String estado;
  final String? tipoPagamento;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final double? valorRecebido;
  final InvoiceCustomerSummary? cliente;
  final InvoiceTerminalSummary? terminal;
  final InvoiceUserSummary? user;
  final int itemCount;
  final int paymentCount;

  bool get isCancelled => estado.toUpperCase() == 'ANULADA';

  bool get isPaid => estado.toUpperCase() == 'PAGA';

  bool get isPending => estado.toUpperCase() == 'PARCIAL' || estado.toUpperCase() == 'EMITIDA';

  bool get isThermalReceipt => tipo.toUpperCase() == 'FR';

  InvoiceSummary copyWith({
    String? estado,
    DateTime? cancelledAt,
  }) {
    return InvoiceSummary(
      id: id,
      numero: numero,
      serie: serie,
      tipo: tipo,
      documentMode: documentMode,
      subtotal: subtotal,
      ivaTotal: ivaTotal,
      total: total,
      troco: troco,
      estado: estado ?? this.estado,
      tipoPagamento: tipoPagamento,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      valorRecebido: valorRecebido,
      cliente: cliente,
      terminal: terminal,
      user: user,
      itemCount: itemCount,
      paymentCount: paymentCount,
    );
  }
}

class InvoiceCustomerSummary {
  const InvoiceCustomerSummary({
    required this.id,
    required this.nome,
    this.documento,
  });

  final String id;
  final String nome;
  final String? documento;
}

class InvoiceTerminalSummary {
  const InvoiceTerminalSummary({
    required this.id,
    required this.nome,
    this.codigo,
  });

  final String id;
  final String nome;
  final String? codigo;
}

class InvoiceUserSummary {
  const InvoiceUserSummary({
    required this.id,
    required this.name,
    this.role,
  });

  final String id;
  final String name;
  final String? role;
}

class InvoiceQuery {
  const InvoiceQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.clienteId,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.terminalId,
    this.userId,
    this.quickFilter = InvoiceQuickFilter.none,
  });

  final int page;
  final int pageSize;
  final String search;
  final String? clienteId;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? terminalId;
  final String? userId;
  final InvoiceQuickFilter quickFilter;

  InvoiceQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? clienteId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? terminalId,
    String? userId,
    InvoiceQuickFilter? quickFilter,
    bool clearClienteId = false,
    bool clearStatus = false,
    bool clearDateRange = false,
    bool clearTerminalId = false,
    bool clearUserId = false,
  }) {
    return InvoiceQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      clienteId: clearClienteId ? null : (clienteId ?? this.clienteId),
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      terminalId: clearTerminalId ? null : (terminalId ?? this.terminalId),
      userId: clearUserId ? null : (userId ?? this.userId),
      quickFilter: quickFilter ?? this.quickFilter,
    );
  }

  bool get hasFilters {
    return search.trim().isNotEmpty ||
        clienteId != null ||
        status != null ||
        dateFrom != null ||
        dateTo != null ||
        terminalId != null ||
        userId != null ||
        quickFilter != InvoiceQuickFilter.none;
  }
}

enum InvoiceQuickFilter {
  none,
  today,
  week,
  month,
  cancelled,
  paid,
  pending,
}
