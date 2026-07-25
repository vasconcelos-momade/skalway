import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/domain/entities/product_tax_rule.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../services/proforma_invoice_fiscal_calculator.dart';

/// Linha local da fatura proforma (produto ou serviço).
class ProformaInvoiceCartLine {
  ProformaInvoiceCartLine({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.unidade,
    required this.quantidade,
    required this.precoUnitario,
    this.descontoPercent = 0,
    this.observacao,
    this.ativo = true,
    this.product,
    this.service,
    this.taxRule,
    this.allowPriceEdit = true,
    this.proformaInvoiceId,
    this.proformaInvoiceItemId,
    this.persistedSubtotal,
    this.persistedDescontoValor,
    this.persistedValorIva,
    this.persistedTotal,
    this.persistedIvaPercent,
    this.persistedIvaLabel,
  });

  final String id;
  final String nome;
  final String codigo;
  final String unidade;
  final double quantidade;
  final double precoUnitario;
  final double descontoPercent;
  final String? observacao;
  final bool ativo;
  final Product? product;
  final PdvService? service;
  final ProductTaxRule? taxRule;
  final bool allowPriceEdit;
  final String? proformaInvoiceId;
  final String? proformaInvoiceItemId;
  final double? persistedSubtotal;
  final double? persistedDescontoValor;
  final double? persistedValorIva;
  final double? persistedTotal;
  final double? persistedIvaPercent;
  final String? persistedIvaLabel;

  bool get isProduct => product != null;

  ProformaInvoiceFiscalResult get fiscal => ProformaInvoiceFiscalCalculator.calculate(
        quantidade: quantidade,
        precoUnitario: precoUnitario,
        descontoPercent: descontoPercent,
        taxRule: taxRule,
      );

  double get subtotal => persistedSubtotal ?? fiscal.baseCalculo;
  double get descontoValor => persistedDescontoValor ?? fiscal.descontoValor;
  double get valorIva => persistedValorIva ?? fiscal.valorIva;
  double get total => persistedTotal ?? fiscal.total;
  String get ivaLabel => persistedIvaLabel ?? fiscal.ivaLabel;

  factory ProformaInvoiceCartLine.fromProduct(
    Product product, {
    double quantidade = 1,
  }) {
    return ProformaInvoiceCartLine(
      id: 'produto:${product.id}',
      nome: product.nomeComercial,
      codigo: product.barcode ?? product.id,
      unidade: 'un',
      quantidade: quantidade,
      precoUnitario: product.precoVenda,
      ativo: product.ativo,
      product: product,
      taxRule: product.taxRule,
    );
  }

  factory ProformaInvoiceCartLine.fromService(
    PdvService service, {
    double quantidade = 1,
  }) {
    return ProformaInvoiceCartLine(
      id: 'servico:${service.id}',
      nome: service.nome,
      codigo: service.id,
      unidade: 'un',
      quantidade: quantidade,
      precoUnitario: service.preco,
      ativo: true,
      service: service,
      taxRule: const ProductTaxRule(tipo: 'IVA_NORMAL', taxa: 16),
    );
  }

  ProformaInvoiceCartLine copyWith({
    double? quantidade,
    double? precoUnitario,
    double? descontoPercent,
    String? observacao,
    bool clearObservacao = false,
  }) {
    return ProformaInvoiceCartLine(
      id: id,
      nome: nome,
      codigo: codigo,
      unidade: unidade,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      descontoPercent: descontoPercent ?? this.descontoPercent,
      observacao: clearObservacao ? null : (observacao ?? this.observacao),
      ativo: ativo,
      product: product,
      service: service,
      taxRule: taxRule,
      allowPriceEdit: allowPriceEdit,
      proformaInvoiceId: proformaInvoiceId,
      proformaInvoiceItemId: proformaInvoiceItemId,
      persistedSubtotal: persistedSubtotal,
      persistedDescontoValor: persistedDescontoValor,
      persistedValorIva: persistedValorIva,
      persistedTotal: persistedTotal,
      persistedIvaPercent: persistedIvaPercent,
      persistedIvaLabel: persistedIvaLabel,
    );
  }

  double get effectivePrecoUnit => precoUnitario;

  factory ProformaInvoiceCartLine.fromPersistedItem({
    required String proformaInvoiceId,
    required String itemId,
    required String nome,
    required String codigo,
    required String unidade,
    required double quantidade,
    required double precoUnitario,
    required double descontoValor,
    required double subtotal,
    required double valorIva,
    required double total,
    required double ivaPercent,
    bool allowPriceEdit = true,
    String? observacao,
    String? ivaLabel,
    Product? product,
    PdvService? service,
  }) {
    final baseBruta = quantidade * precoUnitario;
    final descontoPercent = baseBruta <= 0 ? 0 : (descontoValor / baseBruta) * 100;
    return ProformaInvoiceCartLine(
      id: service != null ? 'servico:${service.id}' : 'produto:${product?.id ?? itemId}',
      nome: nome,
      codigo: codigo,
      unidade: unidade,
      quantidade: quantidade,
      precoUnitario: precoUnitario,
      descontoPercent: descontoPercent.clamp(0, 100).toDouble(),
      ativo: true,
      allowPriceEdit: allowPriceEdit,
      product: product,
      service: service,
      taxRule: product?.taxRule,
      proformaInvoiceId: proformaInvoiceId,
      proformaInvoiceItemId: itemId,
      persistedSubtotal: subtotal,
      persistedDescontoValor: descontoValor,
      persistedValorIva: valorIva,
      persistedTotal: total,
      persistedIvaPercent: ivaPercent,
      persistedIvaLabel: ivaLabel,
      observacao: observacao,
    );
  }
}
