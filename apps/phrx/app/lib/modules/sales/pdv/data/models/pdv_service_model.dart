class PdvServiceModel {
  const PdvServiceModel({
    required this.id,
    required this.nome,
    required this.preco,
    this.tipoServicoClinico,
  });

  final String id;
  final String nome;
  final double preco;
  final String? tipoServicoClinico;

  factory PdvServiceModel.fromJson(Map<String, dynamic> json) {
    return PdvServiceModel(
      id: json['id'].toString(),
      nome: json['nome'] as String? ?? '',
      preco: _toDouble(json['preco']),
      tipoServicoClinico: json['tipoServicoClinico'] as String?,
    );
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
}
