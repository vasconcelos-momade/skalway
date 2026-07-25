enum MetodoPagamentoModel {
  dinheiro('DINHEIRO'),
  mpesa('MPESA'),
  emola('EMOLA'),
  cartao('CARTAO');

  const MetodoPagamentoModel(this.apiValue);

  final String apiValue;
}

class PacienteCheckoutModel {
  PacienteCheckoutModel({
    this.nome,
    this.idade,
    this.nid,
  });

  final String? nome;
  final int? idade;
  final String? nid;

  Map<String, dynamic> toJson() {
    return {
      if (nome != null && nome!.trim().isNotEmpty) 'nome': nome,
      if (idade != null) 'idade': idade,
      if (nid != null && nid!.trim().isNotEmpty) 'nid': nid,
    };
  }
}

class ReceitaCheckoutModel {
  ReceitaCheckoutModel({
    this.numero,
    this.prescritor,
    this.unidadeSanitaria,
  });

  final String? numero;
  final String? prescritor;
  final String? unidadeSanitaria;

  Map<String, dynamic> toJson() {
    return {
      if (numero != null && numero!.trim().isNotEmpty) 'numero': numero,
      if (prescritor != null && prescritor!.trim().isNotEmpty) ...{
        'prescritor': prescritor,
        'medicoNome': prescritor,
      },
      if (unidadeSanitaria != null && unidadeSanitaria!.trim().isNotEmpty)
        'unidadeSanitaria': unidadeSanitaria,
    };
  }
}

class FinalizarVendaItemRequestModel {
  FinalizarVendaItemRequestModel({
    required this.tipo,
    this.produtoId,
    this.servicoId,
    required this.quantidade,
  });

  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final int quantidade;

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      if (produtoId != null) 'produtoId': produtoId,
      if (servicoId != null) 'servicoId': servicoId,
      'quantidade': quantidade,
    };
  }
}

class FinalizarVendaRequestModel {
  final String? clienteId;
  final String terminalId;
  final MetodoPagamentoModel metodoPagamento;
  final String? idempotencyKey;
  final double? valorRecebido;
  final PacienteCheckoutModel? paciente;
  final ReceitaCheckoutModel? receita;
  final String? observacoes;

  FinalizarVendaRequestModel({
    this.clienteId,
    required this.terminalId,
    required this.metodoPagamento,
    this.idempotencyKey,
    this.valorRecebido,
    this.paciente,
    this.receita,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (clienteId != null) 'clienteId': clienteId,
      'terminalId': terminalId,
      'metodoPagamento': metodoPagamento.apiValue,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      if (valorRecebido != null) 'valorRecebido': valorRecebido,
      if (paciente != null) 'paciente': paciente!.toJson(),
      if (receita != null) 'receita': receita!.toJson(),
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}

class FinalizarVendaLoteBreakdownModel {
  FinalizarVendaLoteBreakdownModel({
    required this.loteId,
    required this.quantidade,
    required this.custoUnitario,
  });

  final String loteId;
  final double quantidade;
  final double custoUnitario;

  factory FinalizarVendaLoteBreakdownModel.fromJson(Map<String, dynamic> json) {
    return FinalizarVendaLoteBreakdownModel(
      loteId: json['loteId']?.toString() ?? '',
      quantidade: FinalizarVendaResponseModel._toDouble(json['quantidade']),
      custoUnitario: FinalizarVendaResponseModel._toDouble(json['custoUnitario']),
    );
  }
}

class FinalizarVendaLineModel {
  FinalizarVendaLineModel({
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.precoUnit,
    required this.total,
    this.produtoId,
    this.servicoId,
    this.lotBreakdown = const [],
  });

  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final String descricao;
  final int quantidade;
  final double precoUnit;
  final double total;
  final List<FinalizarVendaLoteBreakdownModel> lotBreakdown;

  factory FinalizarVendaLineModel.fromJson(Map<String, dynamic> json) {
    final rawLots = json['lotBreakdown'] as List<dynamic>? ?? <dynamic>[];
    return FinalizarVendaLineModel(
      tipo: json['tipo']?.toString() ?? 'produto',
      produtoId: json['produtoId']?.toString(),
      servicoId: json['servicoId']?.toString(),
      descricao: json['descricao']?.toString() ?? '',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      precoUnit: FinalizarVendaResponseModel._toDouble(json['precoUnit']),
      total: FinalizarVendaResponseModel._toDouble(json['total']),
      lotBreakdown: rawLots
          .whereType<Map<String, dynamic>>()
          .map(FinalizarVendaLoteBreakdownModel.fromJson)
          .toList(),
    );
  }
}

class FinalizarVendaResponseModel {
  final String id;
  final String numero;
  final String tipo;
  final String documentMode;
  final String estado;
  final double subtotal;
  final double ivaTotal;
  final double total;
  final double troco;
  final List<FinalizarVendaLineModel> items;
  final bool cartReset;
  final String nextCartIdempotencyKey;

  FinalizarVendaResponseModel({
    required this.id,
    required this.numero,
    required this.estado,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    this.tipo = 'FR',
    this.documentMode = 'thermal_80mm',
    this.troco = 0,
    this.items = const [],
    required this.cartReset,
    required this.nextCartIdempotencyKey,
  });

  factory FinalizarVendaResponseModel.fromJson(Map<String, dynamic> json) {
    final total = _toDouble(json['total']);
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final tipo = json['tipo']?.toString().trim().isNotEmpty == true
        ? json['tipo'].toString().trim().toUpperCase()
        : 'FR';
    return FinalizarVendaResponseModel(
      id: (json['faturaId'] ?? json['id']).toString(),
      numero: json['numero'] as String? ?? '',
      tipo: tipo,
      documentMode: json['documentMode']?.toString().trim().isNotEmpty == true
          ? json['documentMode'].toString().trim()
          : (tipo == 'FR' ? 'thermal_80mm' : 'pdf_a4'),
      estado: json['estado'] as String? ?? 'PAGA',
      subtotal: _toDouble(json['subtotal'], fallback: total),
      ivaTotal: _toDouble(json['ivaTotal']),
      total: total,
      troco: _toDouble(json['troco']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(FinalizarVendaLineModel.fromJson)
          .toList(),
      cartReset: json['cartReset'] == true,
      nextCartIdempotencyKey:
          json['nextCartIdempotencyKey']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) {
      return fallback;
    }
    if (value is num) {
      return value.toDouble();
    }
    final normalized = value.toString().trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }
}
