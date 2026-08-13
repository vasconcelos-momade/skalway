import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/pharmacy_service_model.dart';

class PharmacyServiceRemoteDataSource {
  PharmacyServiceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginationResponse<PharmacyServiceModel>> search({
    String? query,
    bool includeInactive = false,
    String? tipoServicoClinico,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantServicos,
        queryParameters: <String, dynamic>{
          if (query != null && query.isNotEmpty) 'q': query,
          if (includeInactive) 'includeInactive': true,
          if (tipoServicoClinico != null && tipoServicoClinico.isNotEmpty)
            'tipoServicoClinico': tipoServicoClinico,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _parsePage(response.data, page, pageSize);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> stats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantServicosStats,
      );
      return ApiEnvelope.unwrapMap(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PharmacyServiceModel> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantServicos,
        data: payload,
      );
      return PharmacyServiceModel.fromJson(ApiEnvelope.unwrapMap(response.data!));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PharmacyServiceModel> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.tenantServico(id),
        data: payload,
      );
      return PharmacyServiceModel.fromJson(ApiEnvelope.unwrapMap(response.data!));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantServico(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  PaginationResponse<PharmacyServiceModel> _parsePage(
    Map<String, dynamic>? data,
    int page,
    int pageSize,
  ) {
    if (data == null) {
      return const PaginationResponse<PharmacyServiceModel>(items: []);
    }
    final payload = ApiEnvelope.unwrapMap(data);
    final rawItems = payload['items'] ?? payload['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PharmacyServiceModel.fromJson)
            .toList()
        : <PharmacyServiceModel>[];
    final meta = payload['meta'] is Map<String, dynamic>
        ? payload['meta'] as Map<String, dynamic>
        : payload;
    return PaginationResponse<PharmacyServiceModel>(
      items: items,
      page: meta['page'] is int ? meta['page'] as int : page,
      pageSize: meta['pageSize'] is int ? meta['pageSize'] as int : pageSize,
      hasMore: meta['hasMore'] == true,
      totalCount: meta['totalCount'] is int
          ? meta['totalCount'] as int
          : int.tryParse(meta['totalCount']?.toString() ?? ''),
    );
  }
}

final pharmacyServiceRemoteDataSourceProvider =
    Provider<PharmacyServiceRemoteDataSource>((ref) {
  return PharmacyServiceRemoteDataSource(ref.watch(dioProvider));
});
