import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/estoque_item_model.dart';

class EstoqueRemoteDataSource {
  EstoqueRemoteDataSource(this._dio);

  final Dio _dio;

  Future<EstoqueDashboardModel> fetchDashboard() async {
    try {
      return await _fetchEstoqueDashboard();
    } on DioException catch (e) {
      if (!_shouldFallback(e)) throw ApiFailure.fromDio(e);
      return _fetchLotesDashboardFallback();
    }
  }

  Future<PaginationResponse<EstoqueItemModel>> search({
    String? query,
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
    String? validadeDe,
    String? validadeAte,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      return await _searchEstoque(
        query: query,
        categoriaId: categoriaId,
        fornecedorId: fornecedorId,
        estadoSanitario: estadoSanitario,
        disponibilidade: disponibilidade,
        semStock: semStock,
        aExpirar: aExpirar,
        expirado: expirado,
        validadeDe: validadeDe,
        validadeAte: validadeAte,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } on DioException catch (e) {
      if (!_shouldFallback(e)) throw ApiFailure.fromDio(e);
      return _searchLotesFallback(
        query: query,
        fornecedorId: fornecedorId,
        estadoSanitario: estadoSanitario,
        disponibilidade: disponibilidade,
        expirado: expirado,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    }
  }

  Future<EstoqueDashboardModel> _fetchEstoqueDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.tenantDashboardEstoque,
    );
    return EstoqueDashboardModel.fromJson(
      ApiEnvelope.unwrapMap(response.data!),
    );
  }

  Future<EstoqueDashboardModel> _fetchLotesDashboardFallback() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantDashboardLotes,
      );
      final payload = ApiEnvelope.unwrapMap(response.data!);
      return EstoqueDashboardModel(
        produtosEmStock: 0,
        lotesAtivos: _int(payload['totalLotes']),
        produtosSemStock: 0,
        lotesAExpirar: 0,
        lotesExpirados: _int(payload['lotesExpirados']),
        valorTotalInventario: 0,
        lotesEmRecall: 0,
        lotesEmQuarentena: 0,
        lotesIncinerados: 0,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<EstoqueItemModel>> _searchEstoque({
    String? query,
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
    String? validadeDe,
    String? validadeAte,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.tenantEstoque,
      queryParameters: _searchParams(
        query: query,
        categoriaId: categoriaId,
        fornecedorId: fornecedorId,
        estadoSanitario: estadoSanitario,
        disponibilidade: disponibilidade,
        semStock: semStock,
        aExpirar: aExpirar,
        expirado: expirado,
        validadeDe: validadeDe,
        validadeAte: validadeAte,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      ),
    );
    return _parsePage(response.data!, page, pageSize);
  }

  Future<PaginationResponse<EstoqueItemModel>> _searchLotesFallback({
    String? query,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? expirado,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.tenantLotes,
      queryParameters: _searchParams(
        query: query,
        fornecedorId: fornecedorId,
        estadoSanitario: estadoSanitario,
        disponibilidade: disponibilidade,
        expirado: expirado,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      ),
    );
    return _parsePage(response.data!, page, pageSize);
  }

  Map<String, dynamic> _searchParams({
    String? query,
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
    String? validadeDe,
    String? validadeAte,
    required int page,
    required int pageSize,
    String? sortBy,
    String? sortOrder,
  }) {
    return <String, dynamic>{
      'q': ?(query != null && query.isNotEmpty ? query : null),
      'categoriaId': ?categoriaId,
      'fornecedorId': ?fornecedorId,
      'estadoSanitario': ?estadoSanitario,
      'disponibilidade': ?disponibilidade,
      'semStock': ?semStock,
      'aExpirar': ?aExpirar,
      'expirado': ?expirado,
      'validadeDe': ?validadeDe,
      'validadeAte': ?validadeAte,
      'sortBy': ?sortBy,
      'sortOrder': ?sortOrder,
      'page': page,
      'pageSize': pageSize,
    };
  }

  PaginationResponse<EstoqueItemModel> _parsePage(
    Map<String, dynamic> raw,
    int page,
    int pageSize,
  ) {
    final payload = ApiEnvelope.unwrapMap(raw);
    final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(EstoqueItemModel.fromJson)
        .toList();
    return PaginationResponse<EstoqueItemModel>(
      items: items,
      page: payload['page'] as int? ?? page,
      pageSize: payload['pageSize'] as int? ?? pageSize,
      hasMore: payload['hasMore'] as bool? ?? false,
      totalCount: payload['totalCount'] as int?,
    );
  }

  bool _shouldFallback(DioException e) {
    final status = e.response?.statusCode;
    return status == 404 || status == 500 || status == 502 || status == 503;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> updateLotePrecos(
    String loteId, {
    required num precoCompra,
    num? precoVenda,
    String? motivo,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantLotePrecos(loteId),
        data: <String, dynamic>{
          'precoCompra': precoCompra,
          'precoVenda': precoVenda,
          'motivo': ?motivo,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> updateLote(
    String loteId, {
    String? numeroLote,
    String? dataValidade,
    String? dataFabricacao,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantLote(loteId),
        data: <String, dynamic>{
          'numeroLote': ?numeroLote,
          'dataValidade': ?dataValidade,
          'dataFabricacao': ?dataFabricacao,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> movimentacaoSanitaria(
    String loteId, {
    required String tipo,
    required String motivo,
    num? quantidade,
    String? documentoReferencia,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantLoteMovimentacaoSanitaria(loteId),
        data: <String, dynamic>{
          'tipo': tipo,
          'motivo': motivo,
          'quantidade': ?quantidade,
          'documentoReferencia': ?documentoReferencia,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> adjustStock({
    required String produtoId,
    required String loteId,
    required num quantidade,
    required String motivo,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantStockAdjust,
        data: <String, dynamic>{
          'produtoId': produtoId,
          'loteId': loteId,
          'quantidade': quantidade,
          'motivo': motivo,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> moveLoteToQuarentena(
    String loteId, {
    required num quantidade,
    required String motivo,
    String? documentoReferencia,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantLoteQuarentena(loteId),
        data: <String, dynamic>{
          'quantidade': quantidade,
          'motivo': motivo,
          'documentoReferencia': ?documentoReferencia,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> revertLoteQuarentena(
    String loteId, {
    required String motivo,
    num? quantidade,
    String? documentoReferencia,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantLoteLiberarQuarentena(loteId),
        data: <String, dynamic>{
          'quantidade': ?quantidade,
          'motivo': motivo,
          'documentoReferencia': ?documentoReferencia,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> entradaCompra({
    required String produtoId,
    required String fornecedorId,
    required String numeroLote,
    required String dataValidade,
    required num quantidade,
    required num precoCompra,
    required num precoVenda,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantEstoqueEntradaCompra,
        data: <String, dynamic>{
          'produtoId': produtoId,
          'fornecedorId': fornecedorId,
          'numeroLote': numeroLote,
          'dataValidade': dataValidade,
          'quantidade': quantidade,
          'precoCompra': precoCompra,
          'precoVenda': precoVenda,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> createLote({
    required String produtoId,
    required String fornecedorId,
    required String numeroLote,
    required String dataValidade,
    required num quantidadeInicial,
    required num precoCompra,
    required num precoVenda,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantLotes,
        data: <String, dynamic>{
          'produtoId': produtoId,
          'fornecedorId': fornecedorId,
          'numeroLote': numeroLote,
          'dataValidade': dataValidade,
          'quantidadeInicial': quantidadeInicial,
          'precoCompra': precoCompra,
          'precoVenda': precoVenda,
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<ProdutoSearchResult>> searchProdutos({required String query}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantStockProdutosSearch,
        queryParameters: <String, dynamic>{'q': query, 'pageSize': 10},
      );
      final payload = ApiEnvelope.unwrapMap(response.data!);
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>();
      return items
          .map(ProdutoSearchResult.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

class ProdutoSearchResult {
  const ProdutoSearchResult({
    required this.id,
    required this.nomeComercial,
    this.dosagem,
    this.forma,
  });

  final String id;
  final String nomeComercial;
  final String? dosagem;
  final String? forma;

  /// Compatibilidade com usos que ainda leem `.nome`.
  String get nome => nomeComercial;

  String get detalhesLabel {
    final parts = <String>[
      if (dosagem != null && dosagem!.trim().isNotEmpty) dosagem!.trim(),
      if (forma != null && forma!.trim().isNotEmpty) forma!.trim(),
    ];
    return parts.join(' · ');
  }

  String get displayLabel {
    final details = detalhesLabel;
    return details.isEmpty ? nomeComercial : '$nomeComercial · $details';
  }

  factory ProdutoSearchResult.fromJson(Map<String, dynamic> json) {
    return ProdutoSearchResult(
      id: json['id']?.toString() ?? '',
      nomeComercial: json['nomeComercial']?.toString() ??
          json['nome']?.toString() ??
          'Produto',
      dosagem: _nullableString(json['dosagem']),
      forma: _nullableString(json['forma']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

final estoqueRemoteDataSourceProvider = Provider<EstoqueRemoteDataSource>(
  (ref) => EstoqueRemoteDataSource(ref.watch(dioProvider)),
);
