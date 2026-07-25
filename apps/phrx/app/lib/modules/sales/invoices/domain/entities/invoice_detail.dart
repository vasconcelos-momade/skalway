class InvoiceDetail {
  const InvoiceDetail({
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
    this.empresa,
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
  final InvoiceEmpresaInfo? empresa;
  final InvoiceDetailCustomer? cliente;
  final InvoiceDetailTerminal? terminal;
  final InvoiceDetailUser? user;
  final InvoiceDetailUser? cancelledBy;
  final InvoiceCancellationDetail? anulacao;
  final List<InvoiceDetailItem> items;
  final List<InvoiceDetailPayment> payments;
  final InvoiceDetailSummary summary;
  final InvoiceDetailPermissions permissions;
  final InvoiceDetailDocuments documents;

  bool get isCancelled => estado.toUpperCase() == 'ANULADA';

  InvoiceDetail copyWith({
    String? estado,
    DateTime? cancelledAt,
    InvoiceDetailUser? cancelledBy,
    InvoiceCancellationDetail? anulacao,
    InvoiceDetailPermissions? permissions,
  }) {
    return InvoiceDetail(
      id: id,
      numero: numero,
      serie: serie,
      tipo: tipo,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
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
      empresa: empresa,
      cliente: cliente,
      terminal: terminal,
      user: user,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      anulacao: anulacao ?? this.anulacao,
      items: items,
      payments: payments,
      summary: summary,
      permissions: permissions ?? this.permissions,
      documents: documents,
    );
  }
}

class InvoiceEmpresaInfo {
  const InvoiceEmpresaInfo({
    this.nome,
    this.nuit,
    this.endereco,
    this.email,
    this.telefone,
  });

  final String? nome;
  final String? nuit;
  final String? endereco;
  final String? email;
  final String? telefone;
}

class InvoiceDetailCustomer {
  const InvoiceDetailCustomer({
    required this.id,
    required this.nome,
    this.documento,
  });

  final String id;
  final String nome;
  final String? documento;
}

class InvoiceDetailTerminal {
  const InvoiceDetailTerminal({
    required this.id,
    required this.nome,
    this.codigo,
  });

  final String id;
  final String nome;
  final String? codigo;
}

class InvoiceDetailUser {
  const InvoiceDetailUser({
    required this.id,
    required this.name,
    this.role,
  });

  final String id;
  final String name;
  final String? role;
}

class InvoiceCancellationDetail {
  const InvoiceCancellationDetail({
    required this.motivo,
    required this.createdAt,
    this.observacoes,
    this.user,
  });

  final String motivo;
  final String? observacoes;
  final DateTime createdAt;
  final InvoiceDetailUser? user;
}

class InvoiceDetailItem {
  const InvoiceDetailItem({
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
    this.lotes = const <InvoiceDetailItemLot>[],
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
  final List<InvoiceDetailItemLot> lotes;
}

class InvoiceDetailItemLot {
  const InvoiceDetailItemLot({
    required this.loteId,
    required this.codigo,
    required this.quantidade,
    required this.ordemFefo,
  });

  final String loteId;
  final String codigo;
  final double quantidade;
  final int ordemFefo;
}

class InvoiceDetailPayment {
  const InvoiceDetailPayment({
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
}

class InvoiceDetailSummary {
  const InvoiceDetailSummary({
    required this.itemCount,
    required this.paymentCount,
  });

  final int itemCount;
  final int paymentCount;
}

class InvoiceDetailPermissions {
  const InvoiceDetailPermissions({
    required this.canCancel,
    required this.canPrint,
    required this.canExportPdf,
  });

  final bool canCancel;
  final bool canPrint;
  final bool canExportPdf;

  InvoiceDetailPermissions copyWith({
    bool? canCancel,
    bool? canPrint,
    bool? canExportPdf,
  }) {
    return InvoiceDetailPermissions(
      canCancel: canCancel ?? this.canCancel,
      canPrint: canPrint ?? this.canPrint,
      canExportPdf: canExportPdf ?? this.canExportPdf,
    );
  }
}

class InvoiceDetailDocuments {
  const InvoiceDetailDocuments({
    this.mode,
    this.pdfUrl,
    this.printUrl,
  });

  final String? mode;
  final String? pdfUrl;
  final String? printUrl;
}
