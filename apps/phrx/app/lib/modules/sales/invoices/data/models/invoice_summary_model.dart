import '../../domain/entities/invoice_summary.dart';

class InvoiceSummaryModel {
  const InvoiceSummaryModel({
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
  final InvoiceCustomerSummaryModel? cliente;
  final InvoiceTerminalSummaryModel? terminal;
  final InvoiceUserSummaryModel? user;
  final int itemCount;
  final int paymentCount;

  factory InvoiceSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSummaryModel(
      id: _asString(json['id']),
      numero: _asString(json['numero']),
      serie: _asNullableString(json['serie']),
      tipo: _asString(json['tipo'], fallback: 'FT'),
      documentMode: _asNullableString(json['documentMode']),
      subtotal: _asDouble(json['subtotal']),
      ivaTotal: _asDouble(json['ivaTotal']),
      total: _asDouble(json['total']),
      troco: _asDouble(json['troco']),
      estado: _asString(json['estado']),
      tipoPagamento: _asNullableString(json['tipoPagamento']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      cancelledAt: _asDate(json['cancelledAt']),
      valorRecebido: json['valorRecebido'] == null
          ? null
          : _asDouble(json['valorRecebido']),
      cliente: json['cliente'] is Map<String, dynamic>
          ? InvoiceCustomerSummaryModel.fromJson(
              json['cliente'] as Map<String, dynamic>,
            )
          : null,
      terminal: json['terminal'] is Map<String, dynamic>
          ? InvoiceTerminalSummaryModel.fromJson(
              json['terminal'] as Map<String, dynamic>,
            )
          : null,
      user: json['user'] is Map<String, dynamic>
          ? InvoiceUserSummaryModel.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
      itemCount: _asInt(json['itemCount']),
      paymentCount: _asInt(json['paymentCount']),
    );
  }

  InvoiceSummary toEntity() {
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
      estado: estado,
      tipoPagamento: tipoPagamento,
      createdAt: createdAt,
      cancelledAt: cancelledAt,
      valorRecebido: valorRecebido,
      cliente: cliente?.toEntity(),
      terminal: terminal?.toEntity(),
      user: user?.toEntity(),
      itemCount: itemCount,
      paymentCount: paymentCount,
    );
  }
}

class InvoiceCustomerSummaryModel {
  const InvoiceCustomerSummaryModel({
    required this.id,
    required this.nome,
    this.documento,
  });

  final String id;
  final String nome;
  final String? documento;

  factory InvoiceCustomerSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomerSummaryModel(
      id: _asString(json['id']),
      nome: _asString(json['nome'], fallback: 'Cliente'),
      documento: _asNullableString(json['documento']),
    );
  }

  InvoiceCustomerSummary toEntity() {
    return InvoiceCustomerSummary(
      id: id,
      nome: nome,
      documento: documento,
    );
  }
}

class InvoiceTerminalSummaryModel {
  const InvoiceTerminalSummaryModel({
    required this.id,
    required this.nome,
    this.codigo,
  });

  final String id;
  final String nome;
  final String? codigo;

  factory InvoiceTerminalSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceTerminalSummaryModel(
      id: _asString(json['id']),
      nome: _asString(json['nome'], fallback: 'Terminal'),
      codigo: _asNullableString(json['codigo']),
    );
  }

  InvoiceTerminalSummary toEntity() {
    return InvoiceTerminalSummary(
      id: id,
      nome: nome,
      codigo: codigo,
    );
  }
}

class InvoiceUserSummaryModel {
  const InvoiceUserSummaryModel({
    required this.id,
    required this.name,
    this.role,
  });

  final String id;
  final String name;
  final String? role;

  factory InvoiceUserSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceUserSummaryModel(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Operador'),
      role: _asNullableString(json['role']),
    );
  }

  InvoiceUserSummary toEntity() {
    return InvoiceUserSummary(
      id: id,
      name: name,
      role: role,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final normalized = _asNullableString(value);
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _asDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
