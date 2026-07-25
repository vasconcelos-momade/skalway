import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../../domain/dashboard_query.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> executiveDashboard(DashboardQuery query) async {
    return _getMap(ApiConstants.tenantDashboardExecutivo, query.toParams());
  }

  Future<Map<String, dynamic>> financeDashboard(DashboardQuery query) async {
    return _getMap(ApiConstants.tenantDashboardFinanceiro, query.toParams());
  }

  Future<Map<String, dynamic>> pharmacyDashboard(DashboardQuery query) async {
    return _getMap(ApiConstants.tenantDashboardFarmacia, query.toParams());
  }

  Future<Map<String, dynamic>> stockDashboard(DashboardQuery query) async {
    return _getMap(ApiConstants.tenantDashboardStock, query.toParams());
  }

  Future<Map<String, dynamic>> executiveDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _getMap(ApiConstants.tenantDashboardExecutivoTables, {
      'table': table,
      ...query.toParams(includePagination: true, page: page, pageSize: pageSize),
    });
  }

  Future<Map<String, dynamic>> financeDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _getMap(ApiConstants.tenantDashboardFinanceiroTables, {
      'table': table,
      ...query.toParams(includePagination: true, page: page, pageSize: pageSize),
    });
  }

  Future<Map<String, dynamic>> pharmacyDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _getMap(ApiConstants.tenantDashboardFarmaciaTables, {
      'table': table,
      ...query.toParams(includePagination: true, page: page, pageSize: pageSize),
    });
  }

  Future<Map<String, dynamic>> stockDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _getMap(ApiConstants.tenantDashboardStockTables, {
      'table': table,
      ...query.toParams(includePagination: true, page: page, pageSize: pageSize),
    });
  }

  Future<Map<String, dynamic>> _getMap(
    String path, [
    Map<String, dynamic>? params,
  ]) async {
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

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(ref.watch(dioProvider)),
);
