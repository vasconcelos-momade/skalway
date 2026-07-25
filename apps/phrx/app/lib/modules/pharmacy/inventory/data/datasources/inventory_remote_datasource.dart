import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> lotesDashboard() async {
    return _getMap(ApiConstants.tenantDashboardLotes);
  }

  Future<PaginationResponse<Map<String, dynamic>>> searchLotes({
    String? query,
    String? produtoId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? expirado,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    return _getPage(
      ApiConstants.tenantLotes,
      <String, dynamic>{
        'q': ?(query != null && query.isNotEmpty ? query : null),
        'produtoId': ?produtoId,
        'fornecedorId': ?fornecedorId,
        'estadoSanitario': ?estadoSanitario,
        'disponibilidade': ?disponibilidade,
        'expirado': ?expirado,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> getLote(String loteId) async {
    return _getMap(ApiConstants.tenantLote(loteId));
  }

  Future<Map<String, dynamic>> validadesDashboard() async {
    return _getMap(ApiConstants.tenantDashboardValidades);
  }

  Future<PaginationResponse<Map<String, dynamic>>> searchValidades({
    String? query,
    String? bucket,
    int page = 1,
    int pageSize = 20,
  }) async {
    return _getPage(
      ApiConstants.tenantValidades,
      <String, dynamic>{
        'q': ?(query != null && query.isNotEmpty ? query : null),
        'bucket': ?bucket,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> fefoDashboard() async {
    return _getMap(ApiConstants.tenantDashboardFefo);
  }

  Future<PaginationResponse<Map<String, dynamic>>> searchFefoOverview({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    return _getPage(
      ApiConstants.tenantFefoOverview,
      <String, dynamic>{
        'q': ?(query != null && query.isNotEmpty ? query : null),
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<PaginationResponse<Map<String, dynamic>>> searchFefoAudit({
    String? query,
    String? situacao,
    int page = 1,
    int pageSize = 20,
  }) async {
    return _getPage(
      ApiConstants.tenantFefoAudit,
      <String, dynamic>{
        'q': ?(query != null && query.isNotEmpty ? query : null),
        'situacao': ?situacao,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<List<Map<String, dynamic>>> listLoteMovimentos(String loteId) async {
    return _getItems(ApiConstants.tenantLoteMovimentos(loteId));
  }

  Future<List<Map<String, dynamic>>> listLoteReservas(String loteId) async {
    return _getList(ApiConstants.tenantLoteReservas(loteId));
  }

  Future<List<Map<String, dynamic>>> listLoteDispensacoes(String loteId) async {
    return _getList(ApiConstants.tenantLoteDispensacoes(loteId));
  }

  Future<List<Map<String, dynamic>>> listLoteIncineracoes(String loteId) async {
    return _getList(ApiConstants.tenantLoteIncineracoes(loteId));
  }

  Future<Map<String, dynamic>> moveLoteToQuarentena(
    String loteId, {
    required num quantidade,
    required String motivo,
    String? documentoReferencia,
  }) async {
    return _postMap(
      ApiConstants.tenantLoteQuarentena(loteId),
      <String, dynamic>{
        'quantidade': quantidade,
        'motivo': motivo,
        'documentoReferencia': ?(documentoReferencia != null &&
                documentoReferencia.isNotEmpty
            ? documentoReferencia
            : null),
      },
    );
  }

  Future<Map<String, dynamic>> revertLoteQuarentena(
    String loteId, {
    num? quantidade,
    required String motivo,
    String? documentoReferencia,
  }) async {
    return _postMap(
      ApiConstants.tenantLoteLiberarQuarentena(loteId),
      <String, dynamic>{
        'quantidade': ?quantidade,
        'motivo': motivo,
        'documentoReferencia': ?(documentoReferencia != null &&
                documentoReferencia.isNotEmpty
            ? documentoReferencia
            : null),
      },
    );
  }

  Future<Map<String, dynamic>> getLoteSanitarioHistory(String loteId) async {
    return _getMap(ApiConstants.tenantLoteSanitarioHistorico(loteId));
  }

  Future<PaginationResponse<Map<String, dynamic>>> _getPage(
    String path,
    Map<String, dynamic> params,
    int page,
    int pageSize,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: params);
      final payload = ApiEnvelope.unwrapMap(response.data!);
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      return PaginationResponse<Map<String, dynamic>>(
        items: items,
        page: payload['page'] as int? ?? page,
        pageSize: payload['pageSize'] as int? ?? pageSize,
        hasMore: payload['hasMore'] as bool? ?? false,
        totalCount: payload['totalCount'] as int?,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> _getItems(String path) async {
    final payload = await _getMap(path);
    return (payload['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return ApiEnvelope.unwrapList(response.data)
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _postMap(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>(
  (ref) => InventoryRemoteDataSource(ref.watch(dioProvider)),
);
