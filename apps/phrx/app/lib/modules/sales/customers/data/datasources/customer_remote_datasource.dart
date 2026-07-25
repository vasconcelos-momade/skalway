import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/utils/api_list_response.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<PaginationResponse<CustomerModel>> listCustomers(CustomerQuery query);

  Future<CustomerDashboard> getDashboard();

  Future<CustomerDetailModel> getCustomer(String id);

  Future<CustomerDetailModel> createCustomer(Map<String, dynamic> payload);

  Future<CustomerDetailModel> updateCustomer(
    String id,
    Map<String, dynamic> payload,
  );

  Future<void> deleteCustomer(String id);

  Future<PaginationResponse<Map<String, dynamic>>> listCustomerFaturas(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<Map<String, dynamic>>> listCustomerContasReceber(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<Map<String, dynamic>>> listCustomerReceitas(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<Map<String, dynamic>>> listCustomerAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  CustomerRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<CustomerModel>> listCustomers(
    CustomerQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantClientes,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
          if (query.tipo != null) 'tipo': query.tipo,
          if (query.comCredito != null) 'comCredito': query.comCredito,
          if (query.temPrescricao != null)
            'temPrescricao': query.temPrescricao,
        },
      );

      return parseApiListResponse(
        data: response.data,
        itemMapper: CustomerModel.fromJson,
        fallbackPage: query.page,
        fallbackPageSize: query.pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CustomerDashboard> getDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantClientesDashboard,
      );
      final data = response.data;
      if (data == null) {
        return const CustomerDashboard();
      }
      return CustomerDashboard.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CustomerDetailModel> getCustomer(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantCliente(id),
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Cliente não encontrado.');
      return CustomerDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CustomerDetailModel> createCustomer(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantClientes,
        data: payload,
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Resposta inválida ao criar cliente.');
      return CustomerDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CustomerDetailModel> updateCustomer(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.tenantCliente(id),
        data: payload,
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Resposta inválida ao actualizar cliente.');
      return CustomerDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantCliente(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<Map<String, dynamic>>> _listSubResource(
    String path, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: (json) => json,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listCustomerFaturas(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantClienteFaturas(id),
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listCustomerContasReceber(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantClienteContasReceber(id),
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listCustomerReceitas(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantClienteReceitas(id),
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listCustomerAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantClienteAuditoria(id),
        page: page,
        pageSize: pageSize,
      );
}

final customerRemoteDataSourceProvider =
    Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSourceImpl(ref.watch(dioProvider));
});
