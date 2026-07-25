import '../../domain/entities/estoque_dashboard.dart';
import '../../domain/entities/estoque_item.dart';

class EstoqueDashboardModel {
  EstoqueDashboardModel({
    required this.produtosEmStock,
    required this.lotesAtivos,
    required this.produtosSemStock,
    required this.lotesAExpirar,
    required this.lotesExpirados,
    required this.valorTotalInventario,
    this.lotesEmRecall = 0,
    this.lotesEmQuarentena = 0,
    this.lotesIncinerados = 0,
  });

  factory EstoqueDashboardModel.fromJson(Map<String, dynamic> json) {
    return EstoqueDashboardModel(
      produtosEmStock: _int(json['produtosEmStock']),
      lotesAtivos: _int(json['lotesAtivos']),
      produtosSemStock: _int(json['produtosSemStock']),
      lotesAExpirar: _int(json['lotesAExpirar']),
      lotesExpirados: _int(json['lotesExpirados']),
      valorTotalInventario: _num(json['valorTotalInventario']),
      lotesEmRecall: _int(json['lotesEmRecall']),
      lotesEmQuarentena: _int(json['lotesEmQuarentena']),
      lotesIncinerados: _int(json['lotesIncinerados']),
    );
  }

  final int produtosEmStock;
  final int lotesAtivos;
  final int produtosSemStock;
  final int lotesAExpirar;
  final int lotesExpirados;
  final num valorTotalInventario;
  final int lotesEmRecall;
  final int lotesEmQuarentena;
  final int lotesIncinerados;

  EstoqueDashboard toEntity() => EstoqueDashboard(
        produtosEmStock: produtosEmStock,
        lotesAtivos: lotesAtivos,
        produtosSemStock: produtosSemStock,
        lotesAExpirar: lotesAExpirar,
        lotesExpirados: lotesExpirados,
        valorTotalInventario: valorTotalInventario,
        lotesEmRecall: lotesEmRecall,
        lotesEmQuarentena: lotesEmQuarentena,
        lotesIncinerados: lotesIncinerados,
      );
}

class EstoqueItemModel {
  EstoqueItemModel({
    required this.id,
    required this.produtoId,
    this.produtoNomeComercial,
    this.produtoNomeGenerico,
    this.produtoDosagem,
    this.produtoFormaFarmaceutica,
    this.produtoBarcode,
    this.categoriaId,
    this.categoriaNome,
    this.fornecedorId,
    this.fornecedorNome,
    required this.numeroLote,
    this.dataValidade,
    this.diasRestantes,
    this.indicadorValidade,
    this.indicadorStock,
    this.quantidadeDisponivel = 0,
    this.quantidadeTotal = 0,
    this.quantidadeInicial = 0,
    this.quantidadeQuarentena = 0,
    this.quantidadeIncinerada = 0,
    this.precoCompra = 0,
    this.precoVenda,
    this.estadoSanitario,
    this.estadoSanitarioEfetivo,
    this.acoesPermitidas = const [],
    this.disponibilidade,
    this.ultimaAtualizacao,
    this.estoqueMinimo = 0,
  });

  factory EstoqueItemModel.fromJson(Map<String, dynamic> json) {
    final rawAcoes = json['acoesPermitidas'];
    return EstoqueItemModel(
      id: json['id']?.toString() ?? '',
      produtoId: json['produtoId']?.toString() ?? '',
      produtoNomeComercial: json['produtoNomeComercial']?.toString() ??
          json['produtoNome']?.toString(),
      produtoNomeGenerico: json['produtoNomeGenerico']?.toString(),
      produtoDosagem: json['produtoDosagem']?.toString(),
      produtoFormaFarmaceutica: json['produtoFormaFarmaceutica']?.toString(),
      produtoBarcode: json['produtoBarcode']?.toString(),
      categoriaId: json['categoriaId']?.toString(),
      categoriaNome: json['categoriaNome']?.toString(),
      fornecedorId: json['fornecedorId']?.toString(),
      fornecedorNome: json['fornecedorNome']?.toString(),
      numeroLote: json['numeroLote']?.toString() ?? '—',
      dataValidade: _date(json['dataValidade']),
      diasRestantes: _intOrNull(json['diasRestantes']),
      indicadorValidade: json['indicadorValidade']?.toString(),
      indicadorStock: json['indicadorStock']?.toString(),
      quantidadeDisponivel: _readDisponivel(json),
      quantidadeTotal: _readTotal(json),
      quantidadeInicial: _num(json['quantidadeInicial']),
      quantidadeQuarentena: _num(json['quantidadeQuarentena']),
      quantidadeIncinerada: _num(json['quantidadeIncinerada']),
      precoCompra: _num(json['precoCompra']),
      precoVenda: json['precoVenda'] == null ? null : _num(json['precoVenda']),
      estadoSanitario: json['estadoSanitario']?.toString(),
      estadoSanitarioEfetivo: json['estadoSanitarioEfetivo']?.toString(),
      acoesPermitidas: rawAcoes is List
          ? rawAcoes.map((e) => e.toString()).toList()
          : const [],
      disponibilidade: json['disponibilidade']?.toString(),
      ultimaAtualizacao: _date(json['ultimaAtualizacao']),
      estoqueMinimo: _num(json['estoqueMinimo']),
    );
  }

  final String id;
  final String produtoId;
  final String? produtoNomeComercial;
  final String? produtoNomeGenerico;
  final String? produtoDosagem;
  final String? produtoFormaFarmaceutica;
  final String? produtoBarcode;
  final String? categoriaId;
  final String? categoriaNome;
  final String? fornecedorId;
  final String? fornecedorNome;
  final String numeroLote;
  final DateTime? dataValidade;
  final int? diasRestantes;
  final String? indicadorValidade;
  final String? indicadorStock;
  final num quantidadeDisponivel;
  final num quantidadeTotal;
  final num quantidadeInicial;
  final num quantidadeQuarentena;
  final num quantidadeIncinerada;
  final num precoCompra;
  final num? precoVenda;
  final String? estadoSanitario;
  final String? estadoSanitarioEfetivo;
  final List<String> acoesPermitidas;
  final String? disponibilidade;
  final DateTime? ultimaAtualizacao;
  final num estoqueMinimo;

  EstoqueItem toEntity() => EstoqueItem(
        id: id,
        produtoId: produtoId,
        produtoNomeComercial: produtoNomeComercial,
        produtoNomeGenerico: produtoNomeGenerico,
        produtoDosagem: produtoDosagem,
        produtoFormaFarmaceutica: produtoFormaFarmaceutica,
        produtoBarcode: produtoBarcode,
        categoriaId: categoriaId,
        categoriaNome: categoriaNome,
        fornecedorId: fornecedorId,
        fornecedorNome: fornecedorNome,
        numeroLote: numeroLote,
        dataValidade: dataValidade,
        diasRestantes: diasRestantes,
        indicadorValidade: indicadorValidade,
        indicadorStock: indicadorStock,
        quantidadeDisponivel: quantidadeDisponivel,
        quantidadeTotal: quantidadeTotal,
        quantidadeInicial: quantidadeInicial,
        quantidadeQuarentena: quantidadeQuarentena,
        quantidadeIncinerada: quantidadeIncinerada,
        precoCompra: precoCompra,
        precoVenda: precoVenda,
        estadoSanitario: estadoSanitario,
        estadoSanitarioEfetivo: estadoSanitarioEfetivo,
        acoesPermitidas: acoesPermitidas,
        disponibilidade: disponibilidade,
        ultimaAtualizacao: ultimaAtualizacao,
        estoqueMinimo: estoqueMinimo,
      );
}

int _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

num _readDisponivel(Map<String, dynamic> json) {
  if (json.containsKey('quantidadeDisponivel') &&
      json['quantidadeDisponivel'] != null) {
    return _num(json['quantidadeDisponivel']);
  }

  final balance = json['stockBalance'];
  if (balance is Map<String, dynamic> &&
      balance['quantidadeDisponivel'] != null) {
    return _num(balance['quantidadeDisponivel']);
  }

  final total = _readTotal(json);
  final quarentena = _num(json['quantidadeQuarentena']);
  return total > quarentena ? total - quarentena : 0;
}

num _readTotal(Map<String, dynamic> json) {
  if (json.containsKey('quantidadeTotal') && json['quantidadeTotal'] != null) {
    return _num(json['quantidadeTotal']);
  }

  final balance = json['stockBalance'];
  if (balance is Map<String, dynamic> && balance['quantidadeTotal'] != null) {
    return _num(balance['quantidadeTotal']);
  }

  if (json['quantidadeDisponivel'] != null) {
    return _num(json['quantidadeDisponivel']);
  }

  return 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
