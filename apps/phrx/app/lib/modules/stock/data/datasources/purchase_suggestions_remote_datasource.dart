import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../models/purchase_suggestion_models.dart';

class PurchaseSuggestionsRemoteDataSource {
  PurchaseSuggestionsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PurchaseSuggestionsListResponse> fetchSuggestions({
    String? query,
    PurchaseSuggestionOriginFilter originFilter =
        PurchaseSuggestionOriginFilter.todas,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (originFilter != PurchaseSuggestionOriginFilter.todas)
            'origem': switch (originFilter) {
              PurchaseSuggestionOriginFilter.automatica => 'AUTOMATICA',
              PurchaseSuggestionOriginFilter.manual => 'MANUAL',
              PurchaseSuggestionOriginFilter.todas => 'TODAS',
            },
          'page': page,
          'pageSize': pageSize,
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      return PurchaseSuggestionsListResponse.fromJson(payload);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<String> addManualSuggestion({
    required String produtoId,
    required String supplierId,
    required num quantidadeSugerida,
    String? observacao,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
        data: <String, dynamic>{
          'produtoId': produtoId,
          'supplierId': supplierId,
          'quantidadeSugerida': quantidadeSugerida,
          if (observacao != null && observacao.trim().isNotEmpty)
            'observacao': observacao.trim(),
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      return payload['message']?.toString() ?? 'Produto adicionado';
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> removeSuggestion(String produtoId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantCompraSugestao(produtoId),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<String> clearSuggestions() async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      return payload['message']?.toString() ?? 'Lista limpa';
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final purchaseSuggestionsRemoteDataSourceProvider =
    Provider<PurchaseSuggestionsRemoteDataSource>(
  (ref) => PurchaseSuggestionsRemoteDataSource(ref.watch(dioProvider)),
);
