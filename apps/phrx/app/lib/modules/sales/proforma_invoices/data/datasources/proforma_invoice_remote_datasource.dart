import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class ProformaInvoiceRemoteDataSource {
  ProformaInvoiceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantProformaInvoices,
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao criar fatura proforma');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getById(String proformaInvoiceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao carregar fatura proforma');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> update(
    String proformaInvoiceId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao actualizar fatura proforma');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> addItem(
    String proformaInvoiceId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId/itens',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao adicionar item');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateItem(
    String proformaInvoiceId,
    String itemId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId/itens/$itemId',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao actualizar item');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> removeItem(
    String proformaInvoiceId,
    String itemId,
  ) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId/itens/$itemId',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao remover item');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> reject(
    String proformaInvoiceId, {
    String? observacoes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId/rejeitar',
        data: <String, dynamic>{
          if (observacoes != null && observacoes.trim().isNotEmpty)
            'observacoes': observacoes.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao cancelar fatura proforma');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> list({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProformaInvoices,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao listar faturas proforma');
      }
      return ApiEnvelope.unwrapList(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> approve(
    String proformaInvoiceId, {
    String? observacoes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.tenantProformaInvoices}/$proformaInvoiceId/aprovar',
        data: <String, dynamic>{
          if (observacoes != null && observacoes.trim().isNotEmpty)
            'observacoes': observacoes.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao aprovar fatura proforma');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final proformaInvoiceRemoteDataSourceProvider =
    Provider<ProformaInvoiceRemoteDataSource>(
  (ref) => ProformaInvoiceRemoteDataSource(ref.watch(dioProvider)),
);
