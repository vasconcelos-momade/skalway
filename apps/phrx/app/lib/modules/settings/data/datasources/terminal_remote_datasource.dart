import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../models/terminal_model.dart';

abstract class TerminalRemoteDataSource {
  Future<PaginationResponse<TerminalDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  });

  Future<TerminalDetalheModel> create(Map<String, dynamic> payload);
  Future<TerminalDetalheModel> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
}

class TerminalRemoteDataSourceImpl implements TerminalRemoteDataSource {
  TerminalRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<TerminalDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantTerminaisSearch,
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
          .map(TerminalDetalheModel.fromJson)
          .toList();
      return PaginationResponse<TerminalDetalheModel>(
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
  Future<TerminalDetalheModel> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantTerminais,
        data: payload,
      );
      return TerminalDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TerminalDetalheModel> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantTerminal(id),
        data: payload,
      );
      return TerminalDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantTerminal(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final terminalRemoteDataSourceProvider = Provider<TerminalRemoteDataSource>(
  (ref) => TerminalRemoteDataSourceImpl(ref.watch(dioProvider)),
);
