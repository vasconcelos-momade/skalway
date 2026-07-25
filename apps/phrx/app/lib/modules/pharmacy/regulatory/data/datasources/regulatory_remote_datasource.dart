import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class RegulatoryRemoteDataSource {
  RegulatoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> receitasDashboard({
    String? search,
    String? clienteId,
    String? from,
    String? to,
  }) {
    return _getMap(
      '/tenant/regulatory/receitas/dashboard',
      params: {
        'search': ?search,
        'clienteId': ?clienteId,
        'from': ?from,
        'to': ?to,
      },
    );
  }

  Future<PaginationResponse<Map<String, dynamic>>> listReceitas({
    String? search,
    String? clienteId,
    String? status,
    String? origem,
    String? from,
    String? to,
    String? sortBy,
    String? sortDir,
    int page = 1,
    int pageSize = 20,
  }) {
    return _getPage(
      '/tenant/regulatory/receitas',
      {
        'search': ?search,
        'clienteId': ?clienteId,
        'status': ?status,
        'origem': ?origem,
        'from': ?from,
        'to': ?to,
        'sortBy': ?sortBy,
        'sortDir': ?sortDir,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> getReceita(String id) =>
      _getMap('/tenant/regulatory/receitas/$id');

  Future<Map<String, dynamic>> createReceita(Map<String, dynamic> body) =>
      _sendMap('POST', '/tenant/regulatory/receitas', body: body);

  Future<Map<String, dynamic>> updateReceita(
    String id,
    Map<String, dynamic> body,
  ) =>
      _sendMap('PATCH', '/tenant/regulatory/receitas/$id', body: body);

  Future<void> deleteReceita(String id) async {
    try {
      await _dio.delete('/tenant/regulatory/receitas/$id');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> livroReceitasDashboard({
    String? search,
    String? clienteId,
    String? produtoId,
    String? responsavelId,
    String? origem,
    String? tipoMovimento,
  }) {
    return _getMap(
      '/tenant/regulatory/livro-receitas/dashboard',
      params: {
        'search': ?search,
        'clienteId': ?clienteId,
        'produtoId': ?produtoId,
        'responsavelId': ?responsavelId,
        'origem': ?origem,
        'tipoMovimento': ?tipoMovimento,
      },
    );
  }

  Future<PaginationResponse<Map<String, dynamic>>> listLivroReceitas({
    String? search,
    String? clienteId,
    String? produtoId,
    String? responsavelId,
    String? origem,
    String? tipoMovimento,
    String? sortBy,
    String? sortDir,
    int page = 1,
    int pageSize = 20,
  }) {
    return _getPage(
      '/tenant/regulatory/livro-receitas',
      {
        'search': ?search,
        'clienteId': ?clienteId,
        'produtoId': ?produtoId,
        'responsavelId': ?responsavelId,
        'origem': ?origem,
        'tipoMovimento': ?tipoMovimento,
        'sortBy': ?sortBy,
        'sortDir': ?sortDir,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> getLivroReceita(String id) =>
      _getMap('/tenant/regulatory/livro-receitas/$id');

  Future<Map<String, dynamic>> livroPsicotropicosDashboard({
    String? search,
    String? produtoId,
    String? responsavelId,
    String? tipoMovimento,
  }) {
    return _getMap(
      '/tenant/regulatory/livro-psicotropicos/dashboard',
      params: {
        'search': ?search,
        'produtoId': ?produtoId,
        'responsavelId': ?responsavelId,
        'tipoMovimento': ?tipoMovimento,
      },
    );
  }

  Future<PaginationResponse<Map<String, dynamic>>> listLivroPsicotropicos({
    String? search,
    String? produtoId,
    String? responsavelId,
    String? tipoMovimento,
    String? sortBy,
    String? sortDir,
    int page = 1,
    int pageSize = 20,
  }) {
    return _getPage(
      '/tenant/regulatory/livro-psicotropicos',
      {
        'search': ?search,
        'produtoId': ?produtoId,
        'responsavelId': ?responsavelId,
        'tipoMovimento': ?tipoMovimento,
        'sortBy': ?sortBy,
        'sortDir': ?sortDir,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> getLivroPsicotropico(String id) =>
      _getMap('/tenant/regulatory/livro-psicotropicos/$id');

  Future<Map<String, dynamic>> sanitarioDashboard({
    String? search,
    String? from,
    String? to,
  }) {
    return _getMap(
      '/tenant/regulatory/sanitario/dashboard',
      params: {
        'search': ?search,
        'from': ?from,
        'to': ?to,
      },
    );
  }

  Future<PaginationResponse<Map<String, dynamic>>> listSanitario({
    String? search,
    String? estado,
    String? alertaTipo,
    String? produtoId,
    String? sortBy,
    String? sortDir,
    int page = 1,
    int pageSize = 20,
  }) {
    return _getPage(
      '/tenant/regulatory/sanitario',
      {
        'search': ?search,
        'estado': ?estado,
        'alertaTipo': ?alertaTipo,
        'produtoId': ?produtoId,
        'sortBy': ?sortBy,
        'sortDir': ?sortDir,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> getLoteSanitarioHistory(String loteId) =>
      _getMap('/tenant/regulatory/sanitario/lotes/$loteId/historico');

  Future<PaginationResponse<Map<String, dynamic>>> listSanitarioReports({
    String? tipo,
    int page = 1,
    int pageSize = 20,
  }) {
    return _getPage(
      '/tenant/regulatory/sanitario/relatorios',
      {
        'tipo': ?tipo,
        'page': page,
        'pageSize': pageSize,
      },
      page,
      pageSize,
    );
  }

  Future<Map<String, dynamic>> _sendMap(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(method: method),
      );
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<Map<String, dynamic>>> _getPage(
    String path,
    Map<String, dynamic> params,
    int page,
    int pageSize,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params,
      );
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

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params,
      );
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final regulatoryRemoteDataSourceProvider =
    Provider<RegulatoryRemoteDataSource>(
  (ref) => RegulatoryRemoteDataSource(ref.watch(dioProvider)),
);
