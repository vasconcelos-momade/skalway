class CustomerSummary {
  const CustomerSummary({
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
}

class CustomerDashboard {
  const CustomerDashboard({
    this.totalClientes = 0,
    this.novosClientes = 0,
    this.clientesAtivos = 0,
    this.clientesComCredito = 0,
  });

  final int totalClientes;
  final int novosClientes;
  final int clientesAtivos;
  final int clientesComCredito;

  factory CustomerDashboard.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CustomerDashboard(
      totalClientes: asInt(json['totalClientes']),
      novosClientes: asInt(json['novosClientes']),
      clientesAtivos: asInt(json['clientesAtivos']),
      clientesComCredito: asInt(json['clientesComCredito']),
    );
  }
}

class CustomerQuery {
  const CustomerQuery({
    this.page = 1,
    this.pageSize = 10,
    this.search = '',
    this.tipo,
    this.comCredito,
    this.temPrescricao,
  });

  final int page;
  final int pageSize;
  final String search;
  final String? tipo;
  final bool? comCredito;
  final bool? temPrescricao;

  CustomerQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? tipo,
    bool? comCredito,
    bool? temPrescricao,
    bool clearTipo = false,
    bool clearComCredito = false,
    bool clearTemPrescricao = false,
  }) {
    return CustomerQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      comCredito: clearComCredito ? null : (comCredito ?? this.comCredito),
      temPrescricao:
          clearTemPrescricao ? null : (temPrescricao ?? this.temPrescricao),
    );
  }

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      tipo != null ||
      comCredito != null ||
      temPrescricao != null;
}

class CustomerDetail {
  const CustomerDetail({
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

  CustomerSummary toSummary() => CustomerSummary(
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

class CustomerFaturaRef {
  const CustomerFaturaRef({
    required this.id,
    required this.numero,
    required this.total,
    required this.estado,
    required this.createdAt,
    this.serie,
    this.userNome,
  });

  final String id;
  final String numero;
  final String? serie;
  final double total;
  final String estado;
  final DateTime createdAt;
  final String? userNome;
}

class CustomerContaReceber {
  const CustomerContaReceber({
    required this.id,
    required this.valor,
    required this.saldo,
    required this.status,
    required this.createdAt,
    this.vencimento,
    this.faturaNumero,
  });

  final String id;
  final double valor;
  final double saldo;
  final String status;
  final DateTime createdAt;
  final DateTime? vencimento;
  final String? faturaNumero;
}

class CustomerReceitaRef {
  const CustomerReceitaRef({
    required this.id,
    required this.dataReceita,
    this.medicoNome,
    this.numeroReceita,
    this.unidadeSanitaria,
  });

  final String id;
  final DateTime dataReceita;
  final String? medicoNome;
  final String? numeroReceita;
  final String? unidadeSanitaria;
}

class CustomerAuditEntry {
  const CustomerAuditEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.userNome,
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? userNome;
}

class CustomerFormPayload {
  const CustomerFormPayload({
    required this.nome,
    required this.tipo,
    this.telefone,
    this.email,
    this.documento,
    this.nuit,
    this.endereco,
    this.limiteCredito,
    this.temPrescricao = false,
    this.version,
  });

  final String nome;
  final String tipo;
  final String? telefone;
  final String? email;
  final String? documento;
  final String? nuit;
  final String? endereco;
  final double? limiteCredito;
  final bool temPrescricao;
  final int? version;

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'tipo': tipo,
        'temPrescricao': temPrescricao,
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (documento != null && documento!.isNotEmpty) 'documento': documento,
        if (nuit != null && nuit!.isNotEmpty) 'nuit': nuit,
        if (endereco != null && endereco!.isNotEmpty) 'endereco': endereco,
        if (limiteCredito != null) 'limiteCredito': limiteCredito,
        if (version != null) 'version': version,
      };
}
