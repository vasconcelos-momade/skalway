import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/utils/api_list_response.dart';
import '../../../invoices/data/models/invoice_summary_model.dart';
import '../../domain/entities/sales_history.dart';

abstract class SalesHistoryRemoteDataSource {
  Future<PaginationResponse<InvoiceSummaryModel>> listSales(
    SalesHistoryQuery query,
  );

  Future<SalesHistoryDashboard> getDashboard({
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}

class SalesHistoryRemoteDataSourceImpl implements SalesHistoryRemoteDataSource {
  SalesHistoryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<InvoiceSummaryModel>> listSales(
    SalesHistoryQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantVendasHistorico,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.status != null) 'status': query.status,
          if (query.dateFrom != null) 'dateFrom': _formatDate(query.dateFrom!),
          if (query.dateTo != null) 'dateTo': _formatDate(query.dateTo!),
        },
      );

      return parseApiListResponse(
        data: response.data,
        itemMapper: InvoiceSummaryModel.fromJson,
        fallbackPage: query.page,
        fallbackPageSize: query.pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<SalesHistoryDashboard> getDashboard({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantVendasHistoricoDashboard,
        queryParameters: <String, dynamic>{
          if (dateFrom != null) 'dateFrom': _formatDate(dateFrom),
          if (dateTo != null) 'dateTo': _formatDate(dateTo),
        },
      );
      final data = response.data;
      if (data == null) return const SalesHistoryDashboard();
      return SalesHistoryDashboard.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final salesHistoryRemoteDataSourceProvider =
    Provider<SalesHistoryRemoteDataSource>((ref) {
  return SalesHistoryRemoteDataSourceImpl(ref.watch(dioProvider));
});
