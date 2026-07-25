import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/utils/api_list_response.dart';
import '../../domain/entities/audit_entities.dart';

abstract class AuditRemoteDataSource {
  Future<AuditDashboard> getDashboard();

  Future<PaginationResponse<AuditLogEntry>> listLogs(AuditQuery query);

  Future<PaginationResponse<AuditEventSummary>> listEvents(AuditQuery query);
}

class AuditRemoteDataSourceImpl implements AuditRemoteDataSource {
  AuditRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuditDashboard> getDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantAuditoriaDashboard,
      );
      final data = response.data;
      if (data == null) return const AuditDashboard();
      return AuditDashboard.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<AuditLogEntry>> listLogs(AuditQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantAuditoriaLogs,
        queryParameters: _queryParams(query),
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: AuditLogEntry.fromJson,
        fallbackPage: query.page,
        fallbackPageSize: query.pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<AuditEventSummary>> listEvents(
    AuditQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantAuditoriaEventos,
        queryParameters: _queryParams(query, useType: true),
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: AuditEventSummary.fromJson,
        fallbackPage: query.page,
        fallbackPageSize: query.pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Map<String, dynamic> _queryParams(AuditQuery query, {bool useType = false}) {
    return <String, dynamic>{
      'page': query.page,
      'pageSize': query.pageSize,
      if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
      if (query.entity != null) 'entity': query.entity,
      if (!useType && query.action != null) 'action': query.action,
      if (useType && query.type != null) 'type': query.type,
      if (query.dateFrom != null) 'dateFrom': _formatDate(query.dateFrom!),
      if (query.dateTo != null) 'dateTo': _formatDate(query.dateTo!),
    };
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final auditRemoteDataSourceProvider = Provider<AuditRemoteDataSource>((ref) {
  return AuditRemoteDataSourceImpl(ref.watch(dioProvider));
});
