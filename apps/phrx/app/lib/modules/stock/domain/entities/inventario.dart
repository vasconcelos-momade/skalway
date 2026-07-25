enum InventarioStatus { aberto, emContagem, reconciliado, cancelado }

extension InventarioStatusX on InventarioStatus {
  String get apiValue {
    switch (this) {
      case InventarioStatus.aberto:
        return 'ABERTO';
      case InventarioStatus.emContagem:
        return 'EM_CONTAGEM';
      case InventarioStatus.reconciliado:
        return 'RECONCILIADO';
      case InventarioStatus.cancelado:
        return 'CANCELADO';
    }
  }

  String get label {
    switch (this) {
      case InventarioStatus.aberto:
        return 'Aberto';
      case InventarioStatus.emContagem:
        return 'Em contagem';
      case InventarioStatus.reconciliado:
        return 'Concluído';
      case InventarioStatus.cancelado:
        return 'Cancelado';
    }
  }

  bool get isEditable =>
      this == InventarioStatus.aberto || this == InventarioStatus.emContagem;

  bool get canRecordCount => this == InventarioStatus.emContagem;

  bool get canReconcile => this == InventarioStatus.emContagem;

  static InventarioStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'EM_CONTAGEM':
        return InventarioStatus.emContagem;
      case 'RECONCILIADO':
        return InventarioStatus.reconciliado;
      case 'CANCELADO':
        return InventarioStatus.cancelado;
      case 'ABERTO':
      default:
        return InventarioStatus.aberto;
    }
  }
}

class AbrirInventarioRequest {
  const AbrirInventarioRequest({this.observacao});

  final String? observacao;
}

class InventarioResumo {
  const InventarioResumo({
    required this.id,
    required this.codigo,
    this.observacao,
    required this.status,
    required this.iniciadoPorId,
    this.iniciadoPorNome,
    this.reconciliadoPorId,
    this.reconciliadoPorNome,
    required this.iniciadoEm,
    this.reconciliadoEm,
    required this.totalItens,
    required this.itensComDivergencia,
  });

  final String id;
  final String codigo;
  final String? observacao;
  final InventarioStatus status;
  final String iniciadoPorId;
  final String? iniciadoPorNome;
  final String? reconciliadoPorId;
  final String? reconciliadoPorNome;
  final DateTime iniciadoEm;
  final DateTime? reconciliadoEm;
  final int totalItens;
  final int itensComDivergencia;
}

class InventarioItem {
  const InventarioItem({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    this.nomeGenerico,
    this.dosagem,
    this.forma,
    this.apresentacao,
    this.loteId,
    this.numeroLote,
    this.dataValidade,
    required this.estoqueLoteAtual,
    this.fornecedorNome,
    required this.estoqueSistema,
    required this.estoqueContado,
    required this.divergencia,
  });

  final String id;
  final String produtoId;
  final String produtoNome;
  final String? nomeGenerico;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final String? loteId;
  final String? numeroLote;
  final String? dataValidade;
  final double estoqueLoteAtual;
  final String? fornecedorNome;
  final double estoqueSistema;
  final double estoqueContado;
  final double divergencia;

  bool get hasDivergencia => divergencia != 0;
}

class InventarioDetalhe {
  const InventarioDetalhe({
    required this.id,
    required this.codigo,
    this.observacao,
    required this.status,
    required this.iniciadoPorId,
    this.iniciadoPorNome,
    this.reconciliadoPorId,
    this.reconciliadoPorNome,
    required this.iniciadoEm,
    this.reconciliadoEm,
    required this.totalItens,
    required this.itensComDivergencia,
    required this.itens,
  });

  final String id;
  final String codigo;
  final String? observacao;
  final InventarioStatus status;
  final String iniciadoPorId;
  final String? iniciadoPorNome;
  final String? reconciliadoPorId;
  final String? reconciliadoPorNome;
  final DateTime iniciadoEm;
  final DateTime? reconciliadoEm;
  final int totalItens;
  final int itensComDivergencia;
  final List<InventarioItem> itens;

  InventarioDetalhe copyWith({
    String? id,
    String? codigo,
    String? observacao,
    InventarioStatus? status,
    String? iniciadoPorId,
    String? iniciadoPorNome,
    String? reconciliadoPorId,
    String? reconciliadoPorNome,
    DateTime? iniciadoEm,
    DateTime? reconciliadoEm,
    int? totalItens,
    int? itensComDivergencia,
    List<InventarioItem>? itens,
  }) {
    return InventarioDetalhe(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      observacao: observacao ?? this.observacao,
      status: status ?? this.status,
      iniciadoPorId: iniciadoPorId ?? this.iniciadoPorId,
      iniciadoPorNome: iniciadoPorNome ?? this.iniciadoPorNome,
      reconciliadoPorId: reconciliadoPorId ?? this.reconciliadoPorId,
      reconciliadoPorNome: reconciliadoPorNome ?? this.reconciliadoPorNome,
      iniciadoEm: iniciadoEm ?? this.iniciadoEm,
      reconciliadoEm: reconciliadoEm ?? this.reconciliadoEm,
      totalItens: totalItens ?? this.totalItens,
      itensComDivergencia: itensComDivergencia ?? this.itensComDivergencia,
      itens: itens ?? this.itens,
    );
  }
}
