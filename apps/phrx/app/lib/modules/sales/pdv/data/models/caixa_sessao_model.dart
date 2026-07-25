class CaixaSessaoModel {
  const CaixaSessaoModel({
    required this.id,
    required this.caixaId,
    this.terminalId,
    required this.userId,
    required this.abertura,
    required this.sistema,
    this.contado,
    this.diferenca,
    this.observacaoFecho,
    this.fechadoPorId,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.deletedAt,
  });

  final String id;
  final String caixaId;
  final String? terminalId;
  final String userId;
  final double abertura;
  final double sistema;
  final double? contado;
  final double? diferenca;
  final String? observacaoFecho;
  final String? fechadoPorId;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime? deletedAt;

  CaixaSessaoModel copyWith({
    String? id,
    String? caixaId,
    String? terminalId,
    String? userId,
    double? abertura,
    double? sistema,
    double? contado,
    double? diferenca,
    String? observacaoFecho,
    String? fechadoPorId,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    DateTime? deletedAt,
  }) {
    return CaixaSessaoModel(
      id: id ?? this.id,
      caixaId: caixaId ?? this.caixaId,
      terminalId: terminalId ?? this.terminalId,
      userId: userId ?? this.userId,
      abertura: abertura ?? this.abertura,
      sistema: sistema ?? this.sistema,
      contado: contado ?? this.contado,
      diferenca: diferenca ?? this.diferenca,
      observacaoFecho: observacaoFecho ?? this.observacaoFecho,
      fechadoPorId: fechadoPorId ?? this.fechadoPorId,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory CaixaSessaoModel.fromJson(Map<String, dynamic> json) {
    return CaixaSessaoModel(
      id: json['id'].toString(),
      caixaId: json['caixaId'].toString(),
      terminalId: json['terminal']?['id']?.toString(),
      userId: json['userId'].toString(),
      abertura: _toDouble(json['abertura']),
      sistema: _toDouble(json['sistema']),
      contado: _toNullableDouble(json['contado']),
      diferenca: _toNullableDouble(json['diferenca']),
      observacaoFecho: json['observacaoFecho'] as String?,
      fechadoPorId: json['fechadoPorId']?.toString(),
      status: json['status'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      closedAt: _toDateTime(json['closedAt']),
      deletedAt: _toDateTime(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caixaId': caixaId,
      'terminalId': terminalId,
      'userId': userId,
      'abertura': abertura,
      'sistema': sistema,
      'contado': contado,
      'diferenca': diferenca,
      'observacaoFecho': observacaoFecho,
      'fechadoPorId': fechadoPorId,
      'status': status,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
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

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }
}

class CaixaDisponivelModel {
  const CaixaDisponivelModel({
    required this.caixaId,
    required this.terminalId,
    required this.terminalCodigo,
    required this.terminalNome,
    this.localizacao,
  });

  final String caixaId;
  final String terminalId;
  final String terminalCodigo;
  final String terminalNome;
  final String? localizacao;

  factory CaixaDisponivelModel.fromJson(Map<String, dynamic> json) {
    return CaixaDisponivelModel(
      caixaId: json['caixaId'].toString(),
      terminalId: json['terminalId'].toString(),
      terminalCodigo: json['terminalCodigo'] as String? ?? '',
      terminalNome: json['terminalNome'] as String? ?? '',
      localizacao: json['localizacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caixaId': caixaId,
      'terminalId': terminalId,
      'terminalCodigo': terminalCodigo,
      'terminalNome': terminalNome,
      'localizacao': localizacao,
    };
  }
}

class AbrirSessaoCaixaRequestModel {
  final String caixaId;
  final String userId;
  final double valorAbertura;

  AbrirSessaoCaixaRequestModel({
    required this.caixaId,
    required this.userId,
    required this.valorAbertura,
  });

  Map<String, dynamic> toJson() {
    return {
      'caixaId': caixaId,
      'userId': userId,
      'valorAbertura': valorAbertura,
    };
  }
}

class AbrirSessaoCaixaResponseModel {
  final bool success;
  final String sessaoId;
  final String status;

  AbrirSessaoCaixaResponseModel({
    required this.success,
    required this.sessaoId,
    required this.status,
  });

  factory AbrirSessaoCaixaResponseModel.fromJson(Map<String, dynamic> json) {
    return AbrirSessaoCaixaResponseModel(
      success: json['success'] as bool? ?? false,
      sessaoId: json['sessaoId'].toString(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'sessaoId': sessaoId,
      'status': status,
    };
  }
}

class FecharSessaoCaixaRequestModel {
  final String sessaoId;
  final double valorContado;
  final String? observacoes;

  FecharSessaoCaixaRequestModel({
    required this.sessaoId,
    required this.valorContado,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessaoId': sessaoId,
      'valorContado': valorContado,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}

class FecharSessaoCaixaResponseModel {
  final bool success;
  final double valorSistema;
  final double valorContado;
  final double diferenca;
  final String status;

  FecharSessaoCaixaResponseModel({
    required this.success,
    required this.valorSistema,
    required this.valorContado,
    required this.diferenca,
    required this.status,
  });

  FecharSessaoCaixaResponseModel copyWith({
    bool? success,
    double? valorSistema,
    double? valorContado,
    double? diferenca,
    String? status,
  }) {
    return FecharSessaoCaixaResponseModel(
      success: success ?? this.success,
      valorSistema: valorSistema ?? this.valorSistema,
      valorContado: valorContado ?? this.valorContado,
      diferenca: diferenca ?? this.diferenca,
      status: status ?? this.status,
    );
  }

  factory FecharSessaoCaixaResponseModel.fromJson(Map<String, dynamic> json) {
    return FecharSessaoCaixaResponseModel(
      success: json['success'] as bool? ?? false,
      valorSistema: CaixaSessaoModel._toDouble(json['valorSistema']),
      valorContado: CaixaSessaoModel._toDouble(json['valorContado']),
      diferenca: CaixaSessaoModel._toDouble(json['diferenca']),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'valorSistema': valorSistema,
      'valorContado': valorContado,
      'diferenca': diferenca,
      'status': status,
    };
  }
}
