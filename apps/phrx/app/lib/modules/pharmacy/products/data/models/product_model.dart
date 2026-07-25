import '../../domain/entities/product_tax_rule.dart';

class ProductModel {
  const ProductModel({
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    return ProductModel(
      id: json['id'].toString(),
      nomeComercial: (json['nomeComercial'] ?? json['nome'] ?? '').toString(),
      nomeGenerico: (json['nomeGenerico'] ?? json['nomeGenerico']) as String?,
      dosagem: json['dosagem'] as String?,
      forma: json['forma'] as String?,
      apresentacao: json['apresentacao'] as String?,
      ativo: _toBool(json['ativo'] ?? json['activo'], defaultValue: true),
      barcode: json['barcode'] as String?,
      categoriaId: json['categoriaId']?.toString() ??
          (categoria is Map ? (categoria)['id']?.toString() : null),
      categoriaNome: json['categoriaNome'] as String? ??
          (categoria is Map ? (categoria)['nome'] as String? : null),
      categoriaCodigoFnm: json['categoriaCodigoFNM'] as String? ??
          (categoria is Map ? (categoria)['codigoFNM'] as String? : null),
      tipoDispensacao: json['tipoDispensacao'] as String? ?? 'VENDA_LIVRE',
      requiresPrescription: _toBool(json['requiresPrescription']),
      requiresDoubleCheck: _toBool(json['requiresDoubleCheck']),
      requiresPsychotropicBook: _toBool(json['requiresPsychotropicBook']),
      antimicrobiano: _toBool(json['antimicrobiano']),
      requiresManualReview: _toBool(json['requiresManualReview']),
      precoVenda: _toDouble(json['precoVenda']),
      estoqueAtual: _toDouble(json['estoqueAtual']),
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
      numLotes: _toInt(json['numLotes']),
      lote: _readLote(json),
      dataValidade: _readDataValidade(json),
      proximaValidade: _readProximaValidade(json),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      taxRule: _parseTaxRule(json['taxRule'], parent: json),
    );
  }

  static ProductTaxRule? _parseTaxRule(
    dynamic value, {
    Map<String, dynamic>? parent,
  }) {
    final taxRuleId = parent?['taxRuleId']?.toString();
    if (value is! Map<String, dynamic>) {
      if (taxRuleId == null || taxRuleId.isEmpty) {
        return null;
      }
      return ProductTaxRule(
        id: taxRuleId,
        tipo: parent?['taxRuleTipo'] as String? ?? 'IVA_NORMAL',
        taxa: _toDouble(parent?['taxaIva'] ?? parent?['taxRuleTaxa']),
        codigo: parent?['taxRuleCodigo'] as String?,
        nome: parent?['taxRuleNome'] as String?,
        descricao: parent?['taxRuleDescricao'] as String?,
        ativo: _toBool(parent?['taxRuleAtivo'], defaultValue: true),
      );
    }
    return ProductTaxRule(
      id: value['id']?.toString() ?? taxRuleId,
      tipo: value['tipo'] as String? ?? 'IVA_NORMAL',
      taxa: _toDouble(value['taxa']),
      codigo: value['codigo'] as String?,
      nome: value['nome'] as String?,
      descricao: value['descricao'] as String?,
      ativo: _toBool(value['ativo'], defaultValue: true),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readProximaValidade(Map<String, dynamic> json) {
    final direct = json['proximaValidade'];
    if (direct is String && direct.trim().isNotEmpty) {
      return DateTime.tryParse(direct);
    }
    return _readDataValidade(json);
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

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return defaultValue;
  }

  static String? _readLote(Map<String, dynamic> json) {
    final direct = json['lote'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    return _firstLote(json['lotes']);
  }

  static DateTime? _readDataValidade(Map<String, dynamic> json) {
    final direct = json['dataValidade'];
    if (direct is String && direct.trim().isNotEmpty) {
      return DateTime.tryParse(direct);
    }
    return _firstDataValidade(json['lotes']);
  }

  static String? _firstLote(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first['numeroLote'] as String?;
      }
    }
    return null;
  }

  static DateTime? _firstDataValidade(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        final dataValidadeStr = first['dataValidade'] as String?;
        if (dataValidadeStr != null) {
          return DateTime.tryParse(dataValidadeStr);
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeComercial': nomeComercial,
      'nomeGenerico': nomeGenerico,
      'dosagem': dosagem,
      'forma': forma,
      'apresentacao': apresentacao,
      'ativo': ativo,
      'activo': ativo,
      'barcode': barcode,
      'categoriaId': categoriaId,
      'tipoDispensacao': tipoDispensacao,
      'requiresPrescription': requiresPrescription,
      'requiresDoubleCheck': requiresDoubleCheck,
      'requiresPsychotropicBook': requiresPsychotropicBook,
      'precoVenda': precoVenda,
      'estoqueAtual': estoqueAtual,
      'estoqueMinimo': estoqueMinimo,
      'taxRuleId': taxRule?.id,
      'lote': lote,
      'dataValidade': dataValidade?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
