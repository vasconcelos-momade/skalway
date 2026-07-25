import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_service.dart';

/// Linha do carrinho PDV (produto ou serviço).
class PdvCartLine {
  const PdvCartLine._({
    required this.id,
    required this.nome,
    required this.precoUnitario,
    required this.qty,
    required this.lineTotal,
    required this.baseCalculo,
    required this.valorIva,
    required this.ivaLabel,
    this.faturaItemId,
    this.product,
    this.service,
  });

  factory PdvCartLine.product(
    Product product,
    int qty, {
    String? faturaItemId,
    double? lineTotal,
    double? baseCalculo,
    double? valorIva,
    String? ivaLabel,
  }) {
    final total = lineTotal ?? product.precoVenda * qty;
    return PdvCartLine._(
      id: 'produto:${product.id}',
      faturaItemId: faturaItemId,
      nome: product.nomeComercial,
      precoUnitario: product.precoVenda,
      qty: qty,
      lineTotal: total,
      baseCalculo: baseCalculo ?? total,
      valorIva: valorIva ?? 0,
      ivaLabel: ivaLabel ?? 'IVA',
      product: product,
    );
  }

  factory PdvCartLine.fromCatalogProduct(Product product, int qty) =>
      PdvCartLine.product(product, qty);

  factory PdvCartLine.service(
    PdvService service,
    int qty, {
    String? faturaItemId,
    double? lineTotal,
    double? baseCalculo,
    double? valorIva,
    String? ivaLabel,
  }) {
    final total = lineTotal ?? service.preco * qty;
    return PdvCartLine._(
      id: 'servico:${service.id}',
      faturaItemId: faturaItemId,
      nome: service.nome,
      precoUnitario: service.preco,
      qty: qty,
      lineTotal: total,
      baseCalculo: baseCalculo ?? total,
      valorIva: valorIva ?? 0,
      ivaLabel: ivaLabel ?? 'IVA',
      service: service,
    );
  }

  final String id;
  final String nome;
  final double precoUnitario;
  final int qty;
  final double lineTotal;
  final double baseCalculo;
  final double valorIva;
  final String ivaLabel;
  /// ID do `fatura_itens` no backend (obrigatório para +/- e remover via API).
  final String? faturaItemId;
  final Product? product;
  final PdvService? service;

  bool get isProduct => product != null;

  bool get canMutateViaApi =>
      faturaItemId != null && faturaItemId!.isNotEmpty;
}
