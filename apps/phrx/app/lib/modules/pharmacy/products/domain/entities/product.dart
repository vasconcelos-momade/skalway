import 'product_tax_rule.dart';

class Product {
  const Product({
    required this.id,
    required this.nomeComercial,
    this.nomeGenerico,
    this.dosagem,
    this.forma,
    this.apresentacao,
    required this.ativo,
    this.barcode,
    this.categoriaId,
    this.categoriaNome,
    this.categoriaCodigoFnm,
    required this.tipoDispensacao,
    required this.requiresPrescription,
    required this.requiresDoubleCheck,
    required this.requiresPsychotropicBook,
    this.antimicrobiano = false,
    this.requiresManualReview = false,
    required this.precoVenda,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    this.numLotes = 0,
    this.lote,
    this.dataValidade,
    this.proximaValidade,
    this.createdAt,
    this.taxRule,
  });

  final String id;
  final String nomeComercial;
  final String? nomeGenerico;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final bool ativo;
  final String? barcode;
  final String? categoriaId;
  final String? categoriaNome;
  final String? categoriaCodigoFnm;
  final String tipoDispensacao;
  final bool requiresPrescription;
  final bool requiresDoubleCheck;
  final bool requiresPsychotropicBook;
  final bool antimicrobiano;
  final bool requiresManualReview;
  final double precoVenda;
  final double estoqueAtual;
  final double estoqueMinimo;
  final int numLotes;
  final String? lote;
  final DateTime? dataValidade;
  final DateTime? proximaValidade;
  final DateTime? createdAt;
  final ProductTaxRule? taxRule;

  bool get isAntimicrobianoFnm =>
      categoriaCodigoFnm == 'ANTIMICROBIANOS' ||
      categoriaNome == 'ANTIMICROBIANOS';
}
