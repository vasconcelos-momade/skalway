import '../../domain/entities/invoice_detail.dart';

class InvoiceDetailModel {
  const InvoiceDetailModel({
    required this.id,
    required this.numero,
    required this.serie,
    required this.tipo,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    required this.subtotal,
    required this.desconto,
    required this.ivaTotal,
    required this.total,
    required this.troco,
    required this.moeda,
    required this.tipoPagamento,
    required this.tipoOperacao,
    required this.items,
    required this.payments,
    required this.summary,
    required this.permissions,
    required this.documents,
    this.cancelledAt,
    this.qrCode,
    this.valorRecebido,
    this.cliente,
    this.terminal,
    this.user,
    this.cancelledBy,
    this.anulacao,
  });

  final String id;
  final String numero;
  final String? serie;
  final String tipo;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final double subtotal;
  final double desconto;
  final double ivaTotal;
  final double total;
  final double troco;
  final String moeda;
  final String? tipoPagamento;
  final String? tipoOperacao;
  final String? qrCode;
  final double? valorRecebido;
  final InvoiceDetailCustomerModel? cliente;
  final InvoiceDetailTerminalModel? terminal;
  final InvoiceDetailUserModel? user;
  final InvoiceDetailUserModel? cancelledBy;
  final InvoiceCancellationDetailModel? anulacao;
  final List<InvoiceDetailItemModel> items;
  final List<InvoiceDetailPaymentModel> payments;
  final InvoiceDetailSummaryModel summary;
  final InvoiceDetailPermissionsModel permissions;
  final InvoiceDetailDocumentsModel documents;

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      id: _asString(json['id']),
      numero: _asString(json['numero']),
      serie: _asNullableString(json['serie']),
      tipo: _asString(json['tipo']),
      estado: _asString(json['estado']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      updatedAt:
          _asDate(json['updatedAt']) ?? _asDate(json['createdAt']) ?? DateTime.now(),
      cancelledAt: _asDate(json['cancelledAt']),
      subtotal: _asDouble(json['subtotal']),
      desconto: _asDouble(json['desconto']),
      ivaTotal: _asDouble(json['ivaTotal']),
      total: _asDouble(json['total']),
      troco: _asDouble(json['troco']),
      moeda: _asString(json['moeda'], fallback: 'MT'),
      tipoPagamento: _asNullableString(json['tipoPagamento']),
      tipoOperacao: _asNullableString(json['tipoOperacao']),
      qrCode: _asNullableString(json['qrCode']),
      valorRecebido: json['valorRecebido'] == null
          ? null
          : _asDouble(json['valorRecebido']),
      cliente: json['cliente'] is Map<String, dynamic>
          ? InvoiceDetailCustomerModel.fromJson(
              json['cliente'] as Map<String, dynamic>,
            )
          : null,
      terminal: json['terminal'] is Map<String, dynamic>
          ? InvoiceDetailTerminalModel.fromJson(
              json['terminal'] as Map<String, dynamic>,
            )
          : null,
      user: json['user'] is Map<String, dynamic>
          ? InvoiceDetailUserModel.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
      cancelledBy: json['cancelledBy'] is Map<String, dynamic>
          ? InvoiceDetailUserModel.fromJson(
              json['cancelledBy'] as Map<String, dynamic>,
            )
          : null,
      anulacao: json['anulacao'] is Map<String, dynamic>
          ? InvoiceCancellationDetailModel.fromJson(
              json['anulacao'] as Map<String, dynamic>,
            )
          : null,
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceDetailItemModel.fromJson)
          .toList(growable: false),
      payments: (json['payments'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceDetailPaymentModel.fromJson)
          .toList(growable: false),
      summary: json['summary'] is Map<String, dynamic>
          ? InvoiceDetailSummaryModel.fromJson(
              json['summary'] as Map<String, dynamic>,
            )
          : const InvoiceDetailSummaryModel(itemCount: 0, paymentCount: 0),
      permissions: json['permissions'] is Map<String, dynamic>
          ? InvoiceDetailPermissionsModel.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : const InvoiceDetailPermissionsModel(
              canCancel: false,
              canPrint: false,
              canExportPdf: false,
            ),
      documents: json['documents'] is Map<String, dynamic>
          ? InvoiceDetailDocumentsModel.fromJson(
              json['documents'] as Map<String, dynamic>,
            )
          : const InvoiceDetailDocumentsModel(),
    );
  }

  InvoiceDetail toEntity() {
    return InvoiceDetail(
      id: id,
      numero: numero,
      serie: serie,
      tipo: tipo,
      estado: estado,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt,
      subtotal: subtotal,
      desconto: desconto,
      ivaTotal: ivaTotal,
      total: total,
      troco: troco,
      moeda: moeda,
      tipoPagamento: tipoPagamento,
      tipoOperacao: tipoOperacao,
      qrCode: qrCode,
      valorRecebido: valorRecebido,
      cliente: cliente?.toEntity(),
      terminal: terminal?.toEntity(),
      user: user?.toEntity(),
      cancelledBy: cancelledBy?.toEntity(),
      anulacao: anulacao?.toEntity(),
      items: items.map((item) => item.toEntity()).toList(growable: false),
      payments: payments.map((item) => item.toEntity()).toList(growable: false),
      summary: summary.toEntity(),
      permissions: permissions.toEntity(),
      documents: documents.toEntity(),
    );
  }
}

class InvoiceDetailCustomerModel {
  const InvoiceDetailCustomerModel({
    required this.id,
    required this.nome,
    this.documento,
  });

  final String id;
  final String nome;
  final String? documento;

  factory InvoiceDetailCustomerModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailCustomerModel(
      id: _asString(json['id']),
      nome: _asString(json['nome'], fallback: 'Cliente'),
      documento: _asNullableString(json['documento']),
    );
  }

  InvoiceDetailCustomer toEntity() {
    return InvoiceDetailCustomer(
      id: id,
      nome: nome,
      documento: documento,
    );
  }
}

class InvoiceDetailTerminalModel {
  const InvoiceDetailTerminalModel({
    required this.id,
    required this.nome,
    this.codigo,
  });

  final String id;
  final String nome;
  final String? codigo;

  factory InvoiceDetailTerminalModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailTerminalModel(
      id: _asString(json['id']),
      nome: _asString(json['nome'], fallback: 'Terminal'),
      codigo: _asNullableString(json['codigo']),
    );
  }

  InvoiceDetailTerminal toEntity() {
    return InvoiceDetailTerminal(
      id: id,
      nome: nome,
      codigo: codigo,
    );
  }
}

class InvoiceDetailUserModel {
  const InvoiceDetailUserModel({
    required this.id,
    required this.name,
    this.role,
  });

  final String id;
  final String name;
  final String? role;

  factory InvoiceDetailUserModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailUserModel(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Utilizador'),
      role: _asNullableString(json['role']),
    );
  }

  InvoiceDetailUser toEntity() {
    return InvoiceDetailUser(
      id: id,
      name: name,
      role: role,
    );
  }
}

class InvoiceCancellationDetailModel {
  const InvoiceCancellationDetailModel({
    required this.motivo,
    required this.createdAt,
    this.observacoes,
    this.user,
  });

  final String motivo;
  final String? observacoes;
  final DateTime createdAt;
  final InvoiceDetailUserModel? user;

  factory InvoiceCancellationDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceCancellationDetailModel(
      motivo: _asString(json['motivo']),
      observacoes: _asNullableString(json['observacoes']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? InvoiceDetailUserModel.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  InvoiceCancellationDetail toEntity() {
    return InvoiceCancellationDetail(
      motivo: motivo,
      observacoes: observacoes,
      createdAt: createdAt,
      user: user?.toEntity(),
    );
  }
}

class InvoiceDetailItemModel {
  const InvoiceDetailItemModel({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.precoUnit,
    required this.baseCalculo,
    required this.iva,
    required this.valorIva,
    required this.taxaAplicada,
    required this.total,
    this.produtoId,
    this.servicoId,
    this.codigoRegraFiscal,
    this.motivoIsencao,
    this.lotes = const <InvoiceDetailItemLotModel>[],
  });

  final String id;
  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final String descricao;
  final double quantidade;
  final double precoUnit;
  final double baseCalculo;
  final double iva;
  final double valorIva;
  final double taxaAplicada;
  final String? codigoRegraFiscal;
  final String? motivoIsencao;
  final double total;
  final List<InvoiceDetailItemLotModel> lotes;

  factory InvoiceDetailItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailItemModel(
      id: _asString(json['id']),
      tipo: _asString(json['tipo']),
      produtoId: _asNullableString(json['produtoId']),
      servicoId: _asNullableString(json['servicoId']),
      descricao: _asString(json['descricao'], fallback: 'Linha'),
      quantidade: _asDouble(json['quantidade']),
      precoUnit: _asDouble(json['precoUnit']),
      baseCalculo: _asDouble(json['baseCalculo']),
      iva: _asDouble(json['iva']),
      valorIva: _asDouble(json['valorIva']),
      taxaAplicada: _asDouble(json['taxaAplicada']),
      codigoRegraFiscal: _asNullableString(json['codigoRegraFiscal']),
      motivoIsencao: _asNullableString(json['motivoIsencao']),
      total: _asDouble(json['total']),
      lotes: (json['lotes'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceDetailItemLotModel.fromJson)
          .toList(growable: false),
    );
  }

  InvoiceDetailItem toEntity() {
    return InvoiceDetailItem(
      id: id,
      tipo: tipo,
      produtoId: produtoId,
      servicoId: servicoId,
      descricao: descricao,
      quantidade: quantidade,
      precoUnit: precoUnit,
      baseCalculo: baseCalculo,
      iva: iva,
      valorIva: valorIva,
      taxaAplicada: taxaAplicada,
      codigoRegraFiscal: codigoRegraFiscal,
      motivoIsencao: motivoIsencao,
      total: total,
      lotes: lotes.map((item) => item.toEntity()).toList(growable: false),
    );
  }
}

class InvoiceDetailItemLotModel {
  const InvoiceDetailItemLotModel({
    required this.loteId,
    required this.codigo,
    required this.quantidade,
    required this.ordemFefo,
  });

  final String loteId;
  final String codigo;
  final double quantidade;
  final int ordemFefo;

  factory InvoiceDetailItemLotModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailItemLotModel(
      loteId: _asString(json['loteId']),
      codigo: _asString(json['codigo'], fallback: '-'),
      quantidade: _asDouble(json['quantidade']),
      ordemFefo: _asInt(json['ordemFefo']),
    );
  }

  InvoiceDetailItemLot toEntity() {
    return InvoiceDetailItemLot(
      loteId: loteId,
      codigo: codigo,
      quantidade: quantidade,
      ordemFefo: ordemFefo,
    );
  }
}

class InvoiceDetailPaymentModel {
  const InvoiceDetailPaymentModel({
    required this.id,
    required this.metodo,
    required this.valor,
    required this.status,
    required this.createdAt,
    this.referencia,
  });

  final String id;
  final String metodo;
  final double valor;
  final String status;
  final DateTime createdAt;
  final String? referencia;

  factory InvoiceDetailPaymentModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailPaymentModel(
      id: _asString(json['id']),
      metodo: _asString(json['metodo'], fallback: '-'),
      valor: _asDouble(json['valor']),
      status: _asString(json['status'], fallback: '-'),
      referencia: _asNullableString(json['referencia']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  InvoiceDetailPayment toEntity() {
    return InvoiceDetailPayment(
      id: id,
      metodo: metodo,
      valor: valor,
      status: status,
      createdAt: createdAt,
      referencia: referencia,
    );
  }
}

class InvoiceDetailSummaryModel {
  const InvoiceDetailSummaryModel({
    required this.itemCount,
    required this.paymentCount,
  });

  final int itemCount;
  final int paymentCount;

  factory InvoiceDetailSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailSummaryModel(
      itemCount: _asInt(json['itemCount']),
      paymentCount: _asInt(json['paymentCount']),
    );
  }

  InvoiceDetailSummary toEntity() {
    return InvoiceDetailSummary(
      itemCount: itemCount,
      paymentCount: paymentCount,
    );
  }
}

class InvoiceDetailPermissionsModel {
  const InvoiceDetailPermissionsModel({
    required this.canCancel,
    required this.canPrint,
    required this.canExportPdf,
  });

  final bool canCancel;
  final bool canPrint;
  final bool canExportPdf;

  factory InvoiceDetailPermissionsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailPermissionsModel(
      canCancel: json['canCancel'] == true,
      canPrint: json['canPrint'] == true,
      canExportPdf: json['canExportPdf'] == true,
    );
  }

  InvoiceDetailPermissions toEntity() {
    return InvoiceDetailPermissions(
      canCancel: canCancel,
      canPrint: canPrint,
      canExportPdf: canExportPdf,
    );
  }
}

class InvoiceDetailDocumentsModel {
  const InvoiceDetailDocumentsModel({
    this.mode,
    this.pdfUrl,
    this.printUrl,
  });

  final String? mode;
  final String? pdfUrl;
  final String? printUrl;

  factory InvoiceDetailDocumentsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailDocumentsModel(
      mode: _asNullableString(json['mode']),
      pdfUrl: _asNullableString(json['pdfUrl']),
      printUrl: _asNullableString(json['printUrl']),
    );
  }

  InvoiceDetailDocuments toEntity() {
    return InvoiceDetailDocuments(
      mode: mode,
      pdfUrl: pdfUrl,
      printUrl: printUrl,
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
