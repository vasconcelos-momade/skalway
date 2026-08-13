class PharmacyService {
  const PharmacyService({
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
}

String pharmacyServiceTipoLabel(String tipo) => switch (tipo) {
      'PESO' => 'Peso',
      'PRESSAO_ARTERIAL' => 'Pressão arterial',
      'TEMPERATURA' => 'Temperatura',
      'GLICEMIA' => 'Glicemia',
      'CONSULTA' => 'Consulta',
      'INJECAO' => 'Injeção',
      'CURATIVO' => 'Curativo',
      'OUTRO' => 'Outro',
      _ => tipo,
    };

const pharmacyServiceTipos = <String>[
  'PESO',
  'PRESSAO_ARTERIAL',
  'TEMPERATURA',
  'GLICEMIA',
  'CONSULTA',
  'INJECAO',
  'CURATIVO',
  'OUTRO',
];
