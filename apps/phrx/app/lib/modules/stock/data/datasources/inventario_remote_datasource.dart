import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/inventario.dart';
import '../models/inventario_model.dart';

abstract class InventarioRemoteDataSource {
  Future<InventarioDetalheModel> abrirInventario(
    AbrirInventarioRequestModel request,
  );
  Future<List<InventarioResumoModel>> listarInventarios({
    InventarioStatus? status,
  });
  Future<PaginationResponse<InventarioItemModel>> listarItensInventario({
    required String inventarioId,
    String? query,
    int page = 1,
    int pageSize = 20,
  });
  Future<InventarioDetalheModel> obterInventario(String inventarioId);
  Future<InventarioDetalheModel> iniciarContagem(String inventarioId);
  Future<InventarioItemModel> registarContagem({
    required String inventarioId,
    required String itemId,
    required double estoqueContado,
  });
  Future<InventarioDetalheModel> reconciliar(String inventarioId);
  Future<InventarioDetalheModel> cancelar(String inventarioId);
}

class InventarioRemoteDataSourceImpl implements InventarioRemoteDataSource {
  InventarioRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<InventarioDetalheModel> abrirInventario(
    AbrirInventarioRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantInventarios,
        data: request.toJson(),
      );
      return InventarioDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao abrir inventário.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<InventarioResumoModel>> listarInventarios({
    InventarioStatus? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantInventarios,
        queryParameters: status == null
            ? null
            : <String, dynamic>{'status': status.apiValue},
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(InventarioResumoModel.fromJson)
            .toList();
      }
      return const <InventarioResumoModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<InventarioItemModel>> listarItensInventario({
    required String inventarioId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantInventarioItens(inventarioId),
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data == null) {
        return const PaginationResponse<InventarioItemModel>(items: []);
      }

      final payload = ApiEnvelope.unwrapMap(data);
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InventarioItemModel.fromJson)
          .toList();

      return PaginationResponse<InventarioItemModel>(
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
  Future<InventarioDetalheModel> obterInventario(String inventarioId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantInventarioDetalhe(inventarioId),
      );
      return InventarioDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao carregar inventário.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<InventarioDetalheModel> iniciarContagem(String inventarioId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantInventarioIniciarContagem(inventarioId),
      );
      return InventarioDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao iniciar contagem.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<InventarioItemModel> registarContagem({
    required String inventarioId,
    required String itemId,
    required double estoqueContado,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantInventarioItem(inventarioId, itemId),
        data: <String, dynamic>{'estoqueContado': estoqueContado},
      );
      return InventarioItemModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao registar contagem.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<InventarioDetalheModel> reconciliar(String inventarioId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantInventarioReconciliar(inventarioId),
      );
      return InventarioDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao reconciliar inventário.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<InventarioDetalheModel> cancelar(String inventarioId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantInventarioCancelar(inventarioId),
      );
      return InventarioDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao cancelar inventário.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  dynamic _unwrap(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['success'] == true && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  Map<String, dynamic> _expectMap(
    Map<String, dynamic>? data, {
    required String fallback,
  }) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return ApiEnvelope.unwrapMap(payload);
    }
    if (payload is Map) {
      return payload.cast<String, dynamic>();
    }
    throw ApiFailure(fallback);
  }
}

final inventarioRemoteDataSourceProvider = Provider<InventarioRemoteDataSource>(
  (ref) {
    return InventarioRemoteDataSourceImpl(ref.watch(dioProvider));
  },
);
