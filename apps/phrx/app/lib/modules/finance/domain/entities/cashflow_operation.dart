/// Valores de `origem` alinhados ao enum do backend (`cashflowOrigemSchema`).
abstract final class CashflowOrigemValues {
  CashflowOrigemValues._();

  static const pagamento = 'PAGAMENTO';
  static const pedido = 'PEDIDO';
  static const compra = 'COMPRA';
  static const sangria = 'SANGRIA';
  static const reforco = 'REFORCO';
  static const outro = 'OUTRO';

  static const all = <String>[
    pagamento,
    pedido,
    compra,
    sangria,
    reforco,
    outro,
  ];
}

enum CashflowOperationKind {
  saida('Saída'),
  suprimento('Suprimento'),
  sangria('Sangria'),
  estorno('Estorno');

  const CashflowOperationKind(this.label);

  final String label;

  static CashflowOperationKind? fromLabel(String label) {
    for (final kind in CashflowOperationKind.values) {
      if (kind.label == label) return kind;
    }
    // Compatibilidade com label legado "Extorno"
    if (label == 'Extorno') return CashflowOperationKind.estorno;
    return null;
  }
}

class CashflowOrigemOption {
  const CashflowOrigemOption({required this.value, required this.label});

  final String value;
  final String label;

  factory CashflowOrigemOption.fromJson(Map<String, dynamic> json) {
    return CashflowOrigemOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class CashflowTerminalContext {
  const CashflowTerminalContext({
    required this.id,
    required this.codigo,
    required this.nome,
    this.localizacao,
  });

  final String id;
  final String codigo;
  final String nome;
  final String? localizacao;

  String get displayName {
    final parts = <String>[
      if (codigo.trim().isNotEmpty) codigo.trim(),
      if (nome.trim().isNotEmpty) nome.trim(),
    ];
    return parts.isEmpty ? 'Terminal' : parts.join(' · ');
  }

  factory CashflowTerminalContext.fromJson(Map<String, dynamic> json) {
    return CashflowTerminalContext(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      localizacao: json['localizacao']?.toString(),
    );
  }
}

class CashflowContext {
  const CashflowContext({
    required this.sessaoId,
    required this.caixaId,
    required this.saldoAtual,
    required this.saldoTotal,
    required this.terminal,
    required this.origens,
  });

  final String sessaoId;
  final String caixaId;
  final num saldoAtual;
  final num saldoTotal;
  final CashflowTerminalContext terminal;
  final List<CashflowOrigemOption> origens;

  factory CashflowContext.fromJson(Map<String, dynamic> json) {
    final rawOrigens = json['origens'];
    return CashflowContext(
      sessaoId: json['sessaoId']?.toString() ?? '',
      caixaId: json['caixaId']?.toString() ?? '',
      saldoAtual: json['saldoAtual'] as num? ?? 0,
      saldoTotal: json['saldoTotal'] as num? ?? 0,
      terminal: CashflowTerminalContext.fromJson(
        json['terminal'] as Map<String, dynamic>? ?? const {},
      ),
      origens: rawOrigens is List
          ? rawOrigens
              .whereType<Map<String, dynamic>>()
              .map(CashflowOrigemOption.fromJson)
              .toList()
          : const [],
    );
  }
}

class CashflowOperationRequest {
  const CashflowOperationRequest({
    required this.valor,
    required this.origem,
    this.descricao,
    this.idempotencyKey,
  });

  final num valor;
  final String origem;
  final String? descricao;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'valor': valor,
        'origem': origem,
        if (descricao != null && descricao!.trim().isNotEmpty)
          'descricao': descricao!.trim(),
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };
}

class CashflowOperationResponse {
  const CashflowOperationResponse({
    required this.movimentoId,
    required this.saldoAtual,
    required this.valor,
    required this.kind,
    required this.origem,
  });

  final String movimentoId;
  final num saldoAtual;
  final num valor;
  final String kind;
  final String origem;

  factory CashflowOperationResponse.fromJson(Map<String, dynamic> json) {
    return CashflowOperationResponse(
      movimentoId: json['movimentoId']?.toString() ?? '',
      saldoAtual: json['saldoAtual'] as num? ?? 0,
      valor: json['valor'] as num? ?? 0,
      kind: json['kind']?.toString() ?? '',
      origem: json['origem']?.toString() ?? '',
    );
  }
}

/// Pré-seleção de UI apenas — a validação final fica no backend.
String? suggestedOrigemForKind(CashflowOperationKind kind) {
  return switch (kind) {
    CashflowOperationKind.suprimento => CashflowOrigemValues.reforco,
    CashflowOperationKind.sangria => CashflowOrigemValues.sangria,
    CashflowOperationKind.estorno => CashflowOrigemValues.outro,
    CashflowOperationKind.saida => null,
  };
}

double? parseCashflowMoney(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String formatCashflowMoney(num value) {
  return '${value.toStringAsFixed(2)} MZN';
}

class CashflowMovementRow {
  const CashflowMovementRow({
    required this.id,
    required this.data,
    required this.tipo,
    required this.valor,
    required this.saldoAnterior,
    required this.saldoFinal,
    required this.descricao,
  });

  final String id;
  final String data;
  final String tipo;
  final num valor;
  final num saldoAnterior;
  final num saldoFinal;
  final String descricao;

  factory CashflowMovementRow.fromJson(Map<String, dynamic> json) {
    return CashflowMovementRow(
      id: json['id']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '—',
      valor: json['valor'] as num? ?? 0,
      saldoAnterior: json['saldoAnterior'] as num? ?? 0,
      saldoFinal: json['saldoFinal'] as num? ?? 0,
      descricao: json['descricao']?.toString() ?? '—',
    );
  }
}

class CashflowMovementsPage {
  const CashflowMovementsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
    this.totalPages,
    this.hasPrevious = false,
  });

  final List<CashflowMovementRow> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final int? totalPages;
  final bool hasPrevious;

  factory CashflowMovementsPage.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(CashflowMovementRow.fromJson)
            .toList()
        : const <CashflowMovementRow>[];

    final page = asInt(json['page'], fallback: 1);
    final pageSize = asInt(json['pageSize'], fallback: 10);
    final totalCount =
        json['totalCount'] == null ? null : asInt(json['totalCount']);

    return CashflowMovementsPage(
      items: items,
      page: page,
      pageSize: pageSize,
      hasMore: json['hasMore'] == true,
      totalCount: totalCount,
      totalPages: json['totalPages'] == null
          ? null
          : asInt(json['totalPages'], fallback: 1),
      hasPrevious: json['hasPrevious'] == true || page > 1,
    );
  }
}
