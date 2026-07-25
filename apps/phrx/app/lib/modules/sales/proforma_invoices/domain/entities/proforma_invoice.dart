class ProformaInvoiceSummary {
  const ProformaInvoiceSummary({
    required this.id,
    required this.numero,
    required this.estado,
    required this.clienteNome,
    required this.total,
    required this.validade,
    required this.createdAt,
    this.itemCount = 0,
  });

  final String id;
  final String numero;
  final String estado;
  final String clienteNome;
  final double total;
  final DateTime validade;
  final DateTime createdAt;
  final int itemCount;
}

class ProformaInvoiceDetail {
  const ProformaInvoiceDetail({
    required this.id,
    required this.numero,
    required this.estado,
    required this.cliente,
    required this.validade,
    required this.createdAt,
    required this.updatedAt,
    required this.subtotal,
    required this.desconto,
    required this.ivaTotal,
    required this.total,
    required this.itemCount,
    required this.items,
    this.clienteId,
    this.nuit,
    this.contacto,
    this.observacoes,
  });

  final String id;
  final String numero;
  final String estado;
  final String cliente;
  final String? clienteId;
  final String? nuit;
  final String? contacto;
  final DateTime validade;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double subtotal;
  final double desconto;
  final double ivaTotal;
  final double total;
  final int itemCount;
  final String? observacoes;
  final List<ProformaInvoiceItem> items;

  bool get canEdit => estado.toUpperCase() == 'PENDENTE';
}

class ProformaInvoiceItem {
  const ProformaInvoiceItem({
    required this.id,
    required this.proformaInvoiceId,
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.precoUnit,
    required this.desconto,
    required this.subtotal,
    required this.iva,
    required this.valorIva,
    required this.total,
    this.produtoId,
    this.servicoId,
    this.codigoRegraFiscal,
    this.produtoNome,
    this.produtoBarcode,
    this.servicoNome,
  });

  final String id;
  final String proformaInvoiceId;
  final String tipo;
  final String descricao;
  final double quantidade;
  final double precoUnit;
  final double desconto;
  final double subtotal;
  final double iva;
  final double valorIva;
  final double total;
  final String? produtoId;
  final String? servicoId;
  final String? codigoRegraFiscal;
  final String? produtoNome;
  final String? produtoBarcode;
  final String? servicoNome;
}

class ProformaInvoiceCreateResult {
  const ProformaInvoiceCreateResult({
    required this.id,
    required this.numero,
    required this.total,
    this.detail,
  });

  final String id;
  final String numero;
  final double total;
  final ProformaInvoiceDetail? detail;
}
