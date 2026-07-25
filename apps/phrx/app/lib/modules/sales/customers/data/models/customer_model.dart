import '../../domain/entities/customer.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.saldoAtual,
    required this.temPrescricao,
    required this.createdAt,
    this.telefone,
    this.email,
    this.documento,
    this.nuit,
    this.limiteCredito,
    this.empresaNome,
    this.faturaCount = 0,
  });

  final String id;
  final String nome;
  final String tipo;
  final double saldoAtual;
  final bool temPrescricao;
  final DateTime createdAt;
  final String? telefone;
  final String? email;
  final String? documento;
  final String? nuit;
  final double? limiteCredito;
  final String? empresaNome;
  final int faturaCount;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    final empresa = json['empresa'];
    final count = json['_count'];

    return CustomerModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'PACIENTE',
      saldoAtual: asDouble(json['saldoAtual']),
      temPrescricao: json['temPrescricao'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      telefone: json['telefone']?.toString(),
      email: json['email']?.toString(),
      documento: json['documento']?.toString(),
      nuit: json['nuit']?.toString(),
      limiteCredito: json['limiteCredito'] == null
          ? null
          : asDouble(json['limiteCredito']),
      empresaNome: empresa is Map<String, dynamic>
          ? empresa['nome']?.toString()
          : null,
      faturaCount: count is Map<String, dynamic>
          ? (count['faturas'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  CustomerSummary toEntity() {
    return CustomerSummary(
      id: id,
      nome: nome,
      tipo: tipo,
      saldoAtual: saldoAtual,
      temPrescricao: temPrescricao,
      createdAt: createdAt,
      telefone: telefone,
      email: email,
      documento: documento,
      nuit: nuit,
      limiteCredito: limiteCredito,
      empresaNome: empresaNome,
      faturaCount: faturaCount,
    );
  }
}

class CustomerDetailModel {
  const CustomerDetailModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.saldoAtual,
    required this.temPrescricao,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.telefone,
    this.email,
    this.documento,
    this.dataNascimento,
    this.sexo,
    this.nuit,
    this.endereco,
    this.empresaId,
    this.empresaNome,
    this.limiteCredito,
    this.faturaCount = 0,
    this.contaReceberCount = 0,
    this.receitaCount = 0,
  });

  final String id;
  final String nome;
  final String tipo;
  final double saldoAtual;
  final bool temPrescricao;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? telefone;
  final String? email;
  final String? documento;
  final DateTime? dataNascimento;
  final String? sexo;
  final String? nuit;
  final String? endereco;
  final String? empresaId;
  final String? empresaNome;
  final double? limiteCredito;
  final int faturaCount;
  final int contaReceberCount;
  final int receitaCount;

  factory CustomerDetailModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    final empresa = json['empresa'];
    final count = json['_count'];

    return CustomerDetailModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'PACIENTE',
      saldoAtual: asDouble(json['saldoAtual']),
      temPrescricao: json['temPrescricao'] == true,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      telefone: json['telefone']?.toString(),
      email: json['email']?.toString(),
      documento: json['documento']?.toString(),
      dataNascimento: json['dataNascimento'] != null
          ? DateTime.tryParse(json['dataNascimento'].toString())
          : null,
      sexo: json['sexo']?.toString(),
      nuit: json['nuit']?.toString(),
      endereco: json['endereco']?.toString(),
      empresaId: json['empresaId']?.toString(),
      empresaNome: empresa is Map<String, dynamic>
          ? empresa['nome']?.toString()
          : null,
      limiteCredito: json['limiteCredito'] == null
          ? null
          : asDouble(json['limiteCredito']),
      faturaCount: count is Map<String, dynamic>
          ? (count['faturas'] as num?)?.toInt() ?? 0
          : 0,
      contaReceberCount: count is Map<String, dynamic>
          ? (count['contasReceber'] as num?)?.toInt() ?? 0
          : 0,
      receitaCount: count is Map<String, dynamic>
          ? (count['receitas'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  CustomerDetail toEntity() => CustomerDetail(
        id: id,
        nome: nome,
        tipo: tipo,
        saldoAtual: saldoAtual,
        temPrescricao: temPrescricao,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
        telefone: telefone,
        email: email,
        documento: documento,
        dataNascimento: dataNascimento,
        sexo: sexo,
        nuit: nuit,
        endereco: endereco,
        empresaId: empresaId,
        empresaNome: empresaNome,
        limiteCredito: limiteCredito,
        faturaCount: faturaCount,
        contaReceberCount: contaReceberCount,
        receitaCount: receitaCount,
      );
}
