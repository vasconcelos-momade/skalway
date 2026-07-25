import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/fornecedor_model.dart';

abstract class FornecedorRemoteDataSource {
  Future<PaginationResponse<FornecedorDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  });

  Future<FornecedorDetalheModel> create(Map<String, dynamic> payload);
  Future<FornecedorDetalheModel> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
}

class FornecedorRemoteDataSourceImpl implements FornecedorRemoteDataSource {
  FornecedorRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<FornecedorDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantFornecedoresSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': page,
          'pageSize': pageSize,
          if (includeInactive) 'includeInactive': true,
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(FornecedorDetalheModel.fromJson)
          .toList();
      return PaginationResponse<FornecedorDetalheModel>(
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

  @override
  Future<FornecedorDetalheModel> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantFornecedores,
        data: payload,
      );
      return FornecedorDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<FornecedorDetalheModel> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantFornecedor(id),
        data: payload,
      );
      return FornecedorDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantFornecedor(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final fornecedorRemoteDataSourceProvider = Provider<FornecedorRemoteDataSource>(
  (ref) => FornecedorRemoteDataSourceImpl(ref.watch(dioProvider)),
);
