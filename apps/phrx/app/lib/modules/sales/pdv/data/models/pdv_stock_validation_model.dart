class PdvStockValidationModel {
  const PdvStockValidationModel({
    required this.canAdd,
    required this.maximumAllowedQuantity,
    required this.mensagem,
  });

  final bool canAdd;
  final int maximumAllowedQuantity;
  final String mensagem;

  factory PdvStockValidationModel.fromJson(Map<String, dynamic> json) {
    return PdvStockValidationModel(
      canAdd: json['canAdd'] as bool? ?? json['permitido'] as bool? ?? false,
      maximumAllowedQuantity:
          _toInt(json['maximumAllowedQuantity'] ?? json['quantidadeDisponivel']),
      mensagem: json['mensagem'] as String? ?? 'Falha ao validar stock.',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}
