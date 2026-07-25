import '../../../../pharmacy/products/domain/entities/product_tax_rule.dart';

class ProformaInvoiceFiscalResult {
  const ProformaInvoiceFiscalResult({
    required this.baseBruta,
    required this.descontoValor,
    required this.baseCalculo,
    required this.taxaPercentual,
    required this.valorIva,
    required this.total,
    this.ivaLabel = 'IVA',
  });

  final double baseBruta;
  final double descontoValor;
  final double baseCalculo;
  final double taxaPercentual;
  final double valorIva;
  final double total;
  final String ivaLabel;
}

abstract final class ProformaInvoiceFiscalCalculator {
  ProformaInvoiceFiscalCalculator._();

  static double normalizeTaxRate(double taxa) {
    if (!taxa.isFinite || taxa <= 0) {
      return 0;
    }
    return taxa > 1 ? taxa / 100 : taxa;
  }

  static ProformaInvoiceFiscalResult calculate({
    required double quantidade,
    required double precoUnitario,
    double descontoPercent = 0,
    ProductTaxRule? taxRule,
  }) {
    final baseBruta = quantidade * precoUnitario;
    final pct = descontoPercent.clamp(0, 100);
    final descontoValor = baseBruta * (pct / 100);
    final baseCalculo = baseBruta - descontoValor;

    final tipo = taxRule?.tipo ?? 'IVA_NORMAL';
    final isExempt = taxRule?.isExempt == true ||
        tipo == 'IVA_ISENTO' ||
        tipo == 'NAO_TRIBUTAVEL';
    final taxRate = isExempt ? 0.0 : normalizeTaxRate(taxRule?.taxa ?? 16);
    final valorIva = baseCalculo * taxRate;
    final total = baseCalculo + valorIva;
    final taxaPercentual = taxRate * 100;

    return ProformaInvoiceFiscalResult(
      baseBruta: baseBruta,
      descontoValor: descontoValor,
      baseCalculo: baseCalculo,
      taxaPercentual: taxaPercentual,
      valorIva: valorIva,
      total: total,
      ivaLabel: taxaPercentual <= 0 ? 'IVA (isento)' : 'IVA (${taxaPercentual.round()}%)',
    );
  }
}
