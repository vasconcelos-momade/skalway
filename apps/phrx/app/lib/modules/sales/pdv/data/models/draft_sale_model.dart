class DraftSaleItemModel {
  final String produtoId;
  final String? loteId;
  final int quantidade;

  DraftSaleItemModel({
    required this.produtoId,
    this.loteId,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() {
    return {
      'produtoId': produtoId,
      if (loteId != null) 'loteId': loteId,
      'quantidade': quantidade,
    };
  }
}

class DraftSaleRequestModel {
  final String? clienteId;
  final String? terminalId;
  final String userId;
  final List<DraftSaleItemModel> items;
  final String? idempotencyKey;

  DraftSaleRequestModel({
    this.clienteId,
    this.terminalId,
    required this.userId,
    required this.items,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      if (clienteId != null) 'clienteId': clienteId,
      if (terminalId != null) 'terminalId': terminalId,
      'userId': userId,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class DraftSaleResponseModel {
  final String id;
  final String numero;
  final String estado;
  final double subtotal;
  final double ivaTotal;
  final double total;

  DraftSaleResponseModel({
    required this.id,
    required this.numero,
    required this.estado,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
  });

  factory DraftSaleResponseModel.fromJson(Map<String, dynamic> json) {
    return DraftSaleResponseModel(
      id: json['id'].toString(),
      numero: json['numero'] as String? ?? 'RASCUNHO',
      estado: json['estado'] as String? ?? 'RASCUNHO',
      subtotal: _toDouble(json['subtotal']),
      ivaTotal: _toDouble(json['ivaTotal']),
      total: _toDouble(json['total']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
