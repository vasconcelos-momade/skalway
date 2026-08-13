import '../../domain/entities/pharmacy_service.dart';

class PharmacyServiceModel {
  const PharmacyServiceModel({
    required this.id,
    required this.nome,
    required this.tipoServicoClinico,
    required this.preco,
    required this.ativo,
    this.taxRuleId,
    this.taxRuleCodigo,
    this.taxRuleNome,
  });

  final String id;
  final String nome;
  final String tipoServicoClinico;
  final double preco;
  final bool ativo;
  final String? taxRuleId;
  final String? taxRuleCodigo;
  final String? taxRuleNome;

  factory PharmacyServiceModel.fromJson(Map<String, dynamic> json) {
    final tax = json['taxRule'];
    return PharmacyServiceModel(
      id: json['id'].toString(),
      nome: json['nome'] as String? ?? '',
      tipoServicoClinico: json['tipoServicoClinico'] as String? ?? 'OUTRO',
      preco: _toDouble(json['preco']),
      ativo: json['ativo'] == true || json['ativo'] == 1,
      taxRuleId: json['taxRuleId']?.toString(),
      taxRuleCodigo: tax is Map<String, dynamic>
          ? tax['codigo']?.toString()
          : null,
      taxRuleNome: tax is Map<String, dynamic> ? tax['nome']?.toString() : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  PharmacyService toEntity() => PharmacyService(
        id: id,
        nome: nome,
        tipoServicoClinico: tipoServicoClinico,
        preco: preco,
        ativo: ativo,
        taxRuleId: taxRuleId,
        taxRuleCodigo: taxRuleCodigo,
        taxRuleNome: taxRuleNome,
      );
}
