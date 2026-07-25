import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../models/printer_model.dart';

abstract class PrinterRemoteDataSource {
  Future<PaginationResponse<PrinterDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool? active,
    String? type,
    String? connection,
  });

  Future<PrinterDetalheModel> get(String id);
  Future<PrinterDetalheModel> create(Map<String, dynamic> payload);
  Future<PrinterDetalheModel> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
  Future<Map<String, dynamic>> test(
    String id, {
    String? message,
    String? platform,
  });
}

class PrinterRemoteDataSourceImpl implements PrinterRemoteDataSource {
  PrinterRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<PrinterDetalheModel>> search({
    String? query,
    int page = 1,
    int pageSize = 20,
    bool? active,
    String? type,
    String? connection,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralPrinters,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': page,
          'pageSize': pageSize,
          'active': ?active,
          if (type != null && type.isNotEmpty) 'type': type,
          if (connection != null && connection.isNotEmpty)
            'connection': connection,
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PrinterDetalheModel.fromJson)
          .toList();
      return PaginationResponse<PrinterDetalheModel>(
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
  Future<PrinterDetalheModel> get(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralPrinter(id),
      );
      return PrinterDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PrinterDetalheModel> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralPrinters,
        data: payload,
      );
      return PrinterDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PrinterDetalheModel> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.centralPrinter(id),
        data: payload,
      );
      return PrinterDetalheModel.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.centralPrinter(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<Map<String, dynamic>> test(
    String id, {
    String? message,
    String? platform,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralPrinterTest(id),
        data: <String, dynamic>{
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          if (platform != null && platform.isNotEmpty) 'platform': platform,
        },
      );
      return ApiEnvelope.unwrapMap(response.data ?? {});
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final printerRemoteDataSourceProvider = Provider<PrinterRemoteDataSource>(
  (ref) => PrinterRemoteDataSourceImpl(ref.watch(dioProvider)),
);
