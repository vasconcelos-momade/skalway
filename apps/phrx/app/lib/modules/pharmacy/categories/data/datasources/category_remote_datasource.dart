import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/category_model.dart';

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginationResponse<CategoryModel>> search({
    String? query,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantCategorias,
        queryParameters: <String, dynamic>{
          if (query != null && query.isNotEmpty) 'q': query,
          if (includeInactive) 'includeInactive': true,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _parsePage(response.data, page, pageSize);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<CategoryModel>> listActive() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.tenantCategoriasAtivas);
      return ApiEnvelope.unwrapList(response.data)
          .map((json) => CategoryModel.fromJson(json))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> stats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantCategoriasStats,
      );
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<CategoryModel> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantCategorias,
        data: payload,
      );
      return CategoryModel.fromJson(ApiEnvelope.unwrapMap(response.data!));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<CategoryModel> update(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.tenantCategoria(id),
        data: payload,
      );
      return CategoryModel.fromJson(ApiEnvelope.unwrapMap(response.data!));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantCategoria(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  PaginationResponse<CategoryModel> _parsePage(
    Map<String, dynamic>? data,
    int page,
    int pageSize,
  ) {
    if (data == null) {
      return const PaginationResponse<CategoryModel>(items: []);
    }
    final payload = ApiEnvelope.unwrapMap(data);
    final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return PaginationResponse<CategoryModel>(
      items: items,
      page: payload['page'] as int? ?? page,
      pageSize: payload['pageSize'] as int? ?? pageSize,
      hasMore: payload['hasMore'] as bool? ?? false,
      totalCount: payload['totalCount'] as int?,
    );
  }
}

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>(
  (ref) => CategoryRemoteDataSource(ref.watch(dioProvider)),
);
