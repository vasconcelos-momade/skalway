import '../../domain/entities/inventario.dart';

class AbrirInventarioRequestModel {
  const AbrirInventarioRequestModel({this.observacao});

  final String? observacao;

  factory AbrirInventarioRequestModel.fromEntity(
    AbrirInventarioRequest entity,
  ) {
    return AbrirInventarioRequestModel(observacao: entity.observacao);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (observacao != null && observacao!.trim().isNotEmpty)
        'observacao': observacao!.trim(),
    };
  }
}

class InventarioResumoModel {
  const InventarioResumoModel({
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

  factory InventarioResumoModel.fromJson(Map<String, dynamic> json) {
    return InventarioResumoModel(
      id: json['id'].toString(),
      codigo: json['codigo'] as String? ?? '',
      observacao: json['observacao'] as String?,
      status: InventarioStatusX.fromApi(json['status'] as String?),
      iniciadoPorId: json['iniciadoPorId'].toString(),
      iniciadoPorNome: json['iniciadoPorNome'] as String?,
      reconciliadoPorId: json['reconciliadoPorId']?.toString(),
      reconciliadoPorNome: json['reconciliadoPorNome'] as String?,
      iniciadoEm: DateTime.parse(json['iniciadoEm'] as String),
      reconciliadoEm: json['reconciliadoEm'] != null
          ? DateTime.tryParse(json['reconciliadoEm'] as String)
          : null,
      totalItens: _toInt(json['totalItens']),
      itensComDivergencia: _toInt(json['itensComDivergencia']),
    );
  }

  InventarioResumo toEntity() {
    return InventarioResumo(
      id: id,
      codigo: codigo,
      observacao: observacao,
      status: status,
      iniciadoPorId: iniciadoPorId,
      iniciadoPorNome: iniciadoPorNome,
      reconciliadoPorId: reconciliadoPorId,
      reconciliadoPorNome: reconciliadoPorNome,
      iniciadoEm: iniciadoEm,
      reconciliadoEm: reconciliadoEm,
      totalItens: totalItens,
      itensComDivergencia: itensComDivergencia,
    );
  }
}

class InventarioItemModel {
  const InventarioItemModel({
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

  factory InventarioItemModel.fromJson(Map<String, dynamic> json) {
    return InventarioItemModel(
      id: json['id'].toString(),
      produtoId: json['produtoId'].toString(),
      produtoNome: json['produtoNomeComercial'] as String? ??
          json['produtoNome'] as String? ??
          '',
      nomeGenerico: json['nomeGenerico'] as String?,
      dosagem: json['dosagem'] as String?,
      forma: json['forma'] as String?,
      apresentacao: json['apresentacao'] as String?,
      loteId: json['loteId']?.toString(),
      numeroLote: json['numeroLote'] as String?,
      dataValidade: json['dataValidade'] as String?,
      estoqueLoteAtual: _toDouble(
        json['estoqueLoteAtual'] ?? json['estoqueSistema'],
      ),
      fornecedorNome: json['fornecedorNome'] as String?,
      estoqueSistema: _toDouble(json['estoqueSistema']),
      estoqueContado: _toDouble(json['estoqueContado']),
      divergencia: _toDouble(json['divergencia']),
    );
  }

  InventarioItem toEntity() {
    return InventarioItem(
      id: id,
      produtoId: produtoId,
      produtoNome: produtoNome,
      nomeGenerico: nomeGenerico,
      dosagem: dosagem,
      forma: forma,
      apresentacao: apresentacao,
      loteId: loteId,
      numeroLote: numeroLote,
      dataValidade: dataValidade,
      estoqueLoteAtual: estoqueLoteAtual,
      fornecedorNome: fornecedorNome,
      estoqueSistema: estoqueSistema,
      estoqueContado: estoqueContado,
      divergencia: divergencia,
    );
  }
}

class InventarioDetalheModel {
  const InventarioDetalheModel({
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
  final List<InventarioItemModel> itens;

  factory InventarioDetalheModel.fromJson(Map<String, dynamic> json) {
    final rawItens = json['itens'];
    final items = rawItens is List
        ? rawItens
              .whereType<Map<String, dynamic>>()
              .map(InventarioItemModel.fromJson)
              .toList()
        : const <InventarioItemModel>[];

    return InventarioDetalheModel(
      id: json['id'].toString(),
      codigo: json['codigo'] as String? ?? '',
      observacao: json['observacao'] as String?,
      status: InventarioStatusX.fromApi(json['status'] as String?),
      iniciadoPorId: json['iniciadoPorId'].toString(),
      iniciadoPorNome: json['iniciadoPorNome'] as String?,
      reconciliadoPorId: json['reconciliadoPorId']?.toString(),
      reconciliadoPorNome: json['reconciliadoPorNome'] as String?,
      iniciadoEm: DateTime.parse(json['iniciadoEm'] as String),
      reconciliadoEm: json['reconciliadoEm'] != null
          ? DateTime.tryParse(json['reconciliadoEm'] as String)
          : null,
      totalItens: _toInt(json['totalItens'], fallback: items.length),
      itensComDivergencia: _toInt(json['itensComDivergencia']),
      itens: items,
    );
  }

  InventarioDetalhe toEntity() {
    return InventarioDetalhe(
      id: id,
      codigo: codigo,
      observacao: observacao,
      status: status,
      iniciadoPorId: iniciadoPorId,
      iniciadoPorNome: iniciadoPorNome,
      reconciliadoPorId: reconciliadoPorId,
      reconciliadoPorNome: reconciliadoPorNome,
      iniciadoEm: iniciadoEm,
      reconciliadoEm: reconciliadoEm,
      totalItens: totalItens,
      itensComDivergencia: itensComDivergencia,
      itens: itens.map((item) => item.toEntity()).toList(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
