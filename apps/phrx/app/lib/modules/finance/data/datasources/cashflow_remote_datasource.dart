import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/cashflow_operation.dart';

abstract class CashflowRemoteDataSource {
  Future<CashflowContext> getContext();

  Future<CashflowMovementsPage> listMovements({
    Map<String, dynamic>? queryParameters,
    required int page,
    required int pageSize,
    String? sortBy,
    String sortDir = 'desc',
  });

  Future<CashflowOperationResponse> registerOperation({
    required CashflowOperationKind kind,
    required CashflowOperationRequest request,
  });
}

class CashflowRemoteDataSourceImpl implements CashflowRemoteDataSource {
  CashflowRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<CashflowContext> getContext() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantFinanceCashflowContext,
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? const {});
      return CashflowContext.fromJson(payload);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CashflowMovementsPage> listMovements({
    Map<String, dynamic>? queryParameters,
    required int page,
    required int pageSize,
    String? sortBy,
    String sortDir = 'desc',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantFinanceCashflowMovimentos,
        queryParameters: <String, dynamic>{
          ...?queryParameters,
          'page': page,
          'pageSize': pageSize,
          if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
          'sortDir': sortDir,
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? const {});
      return CashflowMovementsPage.fromJson(payload);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CashflowOperationResponse> registerOperation({
    required CashflowOperationKind kind,
    required CashflowOperationRequest request,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpointFor(kind),
        data: request.toJson(),
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? const {});
      return CashflowOperationResponse.fromJson(payload);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _endpointFor(CashflowOperationKind kind) {
    return switch (kind) {
      CashflowOperationKind.saida => ApiConstants.tenantFinanceCashflowSaida,
      CashflowOperationKind.suprimento =>
        ApiConstants.tenantFinanceCashflowSuprimento,
      CashflowOperationKind.sangria => ApiConstants.tenantFinanceCashflowSangria,
      CashflowOperationKind.estorno => ApiConstants.tenantFinanceCashflowEstorno,
    };
  }
}

final cashflowRemoteDataSourceProvider = Provider<CashflowRemoteDataSource>((ref) {
  return CashflowRemoteDataSourceImpl(ref.watch(dioProvider));
});
