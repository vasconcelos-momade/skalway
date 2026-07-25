import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/pdv_service_model.dart';

abstract class PdvServiceRemoteDataSource {
  Future<PaginationResponse<PdvServiceModel>> searchServices({
    String? query,
    int page = 1,
    int pageSize = 10,
  });
}

class PdvServiceRemoteDataSourceImpl implements PdvServiceRemoteDataSource {
  PdvServiceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<PdvServiceModel>> searchServices({
    String? query,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosServicosSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      if (data == null) {
        return const PaginationResponse<PdvServiceModel>(items: []);
      }

      final payload = ApiEnvelope.unwrapMap(data);
      final items = (payload['items'] as List<dynamic>? ?? ApiEnvelope.unwrapList(data))
          .map((json) => PdvServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginationResponse<PdvServiceModel>(
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
}

final pdvServiceRemoteDataSourceProvider = Provider<PdvServiceRemoteDataSource>((ref) {
  return PdvServiceRemoteDataSourceImpl(ref.watch(dioProvider));
});
