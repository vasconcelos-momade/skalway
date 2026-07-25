import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/caixa_sessao_model.dart';
import '../models/draft_cart_model.dart';
import '../models/draft_sale_model.dart';
import '../models/finalizar_venda_model.dart';

abstract class PdvRemoteDataSource {
  Future<DraftCartModel> getDraftCart({
    required String idempotencyKey,
  });
  Future<DraftCartModel> addDraftCartItem({
    required String idempotencyKey,
    String? produtoId,
    String? servicoId,
    int quantidade = 1,
    String? loteId,
  });
  Future<DraftCartModel> incrementDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  });
  Future<DraftCartModel> decrementDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  });
  Future<DraftCartModel> removeDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  });
  Future<DraftSaleResponseModel> createDraftSale(DraftSaleRequestModel request);
  Future<FinalizarVendaResponseModel> finalizarVenda(FinalizarVendaRequestModel request);
  Future<AbrirSessaoCaixaResponseModel> abrirSessaoCaixa(AbrirSessaoCaixaRequestModel request);
  Future<FecharSessaoCaixaResponseModel> fecharSessaoCaixa(FecharSessaoCaixaRequestModel request);
  Future<CaixaSessaoModel?> getSessaoCaixaAtual();
  Future<List<CaixaDisponivelModel>> listCaixasDisponiveis();
}

class PdvRemoteDataSourceImpl implements PdvRemoteDataSource {
  PdvRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  ApiFailure _failureFromResponse(
    Map<String, dynamic>? data,
    int? statusCode,
    String fallback,
  ) {
    if (data == null) {
      return ApiFailure(fallback, statusCode: statusCode);
    }
    if (data['success'] == false) {
      final err = data['error'];
      final msg = err is Map ? err['message'] : err;
      return ApiFailure(
        msg is String && msg.isNotEmpty ? msg : fallback,
        statusCode: statusCode,
      );
    }
    final err = data['error'];
    if (err is String && err.isNotEmpty) {
      return ApiFailure(err, statusCode: statusCode);
    }
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return ApiFailure(data['message'] as String, statusCode: statusCode);
    }
    return ApiFailure(fallback, statusCode: statusCode);
  }

  DraftCartModel _parseDraftCart(Map<String, dynamic>? data, String fallback) {
    if (data == null) {
      throw ApiFailure(fallback);
    }
    if (data['success'] == false) {
      throw _failureFromResponse(data, null, fallback);
    }
    return DraftCartModel.fromJson(ApiEnvelope.unwrapMap(data));
  }

  Future<DraftCartModel> _mutateDraftCart(Future<Response<Map<String, dynamic>>> request) async {
    try {
      final response = await request;
      return _parseDraftCart(response.data, 'Resposta inválida do carrinho PDV.');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw _failureFromResponse(
          data,
          e.response?.statusCode,
          'Falha na operação do carrinho.',
        );
      }
      throw ApiFailure.fromDio(e);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<DraftCartModel> getDraftCart({
    required String idempotencyKey,
  }) async {
    return _mutateDraftCart(
      _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftCart,
        queryParameters: {
          'idempotencyKey': idempotencyKey,
        },
      ),
    );
  }

  @override
  Future<DraftCartModel> addDraftCartItem({
    required String idempotencyKey,
    String? produtoId,
    String? servicoId,
    int quantidade = 1,
    String? loteId,
  }) async {
    return _mutateDraftCart(
      _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftCartItems,
        data: DraftCartItemRequestModel(
          idempotencyKey: idempotencyKey,
          produtoId: produtoId,
          servicoId: servicoId,
          quantidade: quantidade,
          loteId: loteId,
        ).toJson(),
      ),
    );
  }

  @override
  Future<DraftCartModel> incrementDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  }) async {
    return _mutateDraftCart(
      _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftCartItemIncrement(itemId),
        data: DraftCartContextRequestModel(idempotencyKey: idempotencyKey).toJson(),
      ),
    );
  }

  @override
  Future<DraftCartModel> decrementDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  }) async {
    return _mutateDraftCart(
      _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftCartItemDecrement(itemId),
        data: DraftCartContextRequestModel(idempotencyKey: idempotencyKey).toJson(),
      ),
    );
  }

  @override
  Future<DraftCartModel> removeDraftCartItem({
    required String idempotencyKey,
    required String itemId,
  }) async {
    return _mutateDraftCart(
      _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftCartItem(itemId),
        data: DraftCartContextRequestModel(idempotencyKey: idempotencyKey).toJson(),
      ),
    );
  }

  @override
  Future<DraftSaleResponseModel> createDraftSale(DraftSaleRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosDraftSale,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao criar rascunho de venda.');
      }
      if (data['success'] == false) {
        throw _failureFromResponse(
          data,
          response.statusCode,
          'Falha ao adicionar item ao carrinho.',
        );
      }

      final cart = DraftCartModel.fromJson(ApiEnvelope.unwrapMap(data));
      return DraftSaleResponseModel(
        id: cart.id,
        numero: cart.numero,
        estado: cart.estado,
        subtotal: cart.subtotal,
        ivaTotal: cart.ivaTotal,
        total: cart.total,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw _failureFromResponse(
          data,
          e.response?.statusCode,
          'Falha ao adicionar item ao carrinho.',
        );
      }
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<FinalizarVendaResponseModel> finalizarVenda(FinalizarVendaRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosFinalizarVenda,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao finalizar venda.');
      }

      return FinalizarVendaResponseModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw _failureFromResponse(
          data,
          e.response?.statusCode,
          'Falha ao finalizar venda.',
        );
      }
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<AbrirSessaoCaixaResponseModel> abrirSessaoCaixa(AbrirSessaoCaixaRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosAbrirSessaoCaixa,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao abrir sessão de caixa.');
      }
      if (data['success'] == false) {
        throw _failureFromResponse(
          data,
          response.statusCode,
          'Não foi possível abrir o caixa.',
        );
      }

      return AbrirSessaoCaixaResponseModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw _failureFromResponse(
          data,
          e.response?.statusCode,
          'Não foi possível abrir o caixa.',
        );
      }
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<FecharSessaoCaixaResponseModel> fecharSessaoCaixa(FecharSessaoCaixaRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosFecharSessaoCaixa,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao fechar sessão de caixa.');
      }
      if (data['success'] == false) {
        throw _failureFromResponse(
          data,
          response.statusCode,
          'Não foi possível fechar o caixa.',
        );
      }

      return FecharSessaoCaixaResponseModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw _failureFromResponse(
          data,
          e.response?.statusCode,
          'Não foi possível fechar o caixa.',
        );
      }
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CaixaSessaoModel?> getSessaoCaixaAtual() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosSessaoCaixaAtual,
      );

      final data = response.data;
      if (data == null) {
        return null;
      }
      final payload = ApiEnvelope.unwrapMap(data);
      if (payload.isEmpty) {
        return null;
      }
      return CaixaSessaoModel.fromJson(payload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      if (e.response?.data == null) {
        throw ApiFailure.fromDio(e);
      }
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<CaixaDisponivelModel>> listCaixasDisponiveis() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosCaixasDisponiveis,
      );

      final data = response.data;
      if (data == null) {
        return <CaixaDisponivelModel>[];
      }
      return ApiEnvelope.unwrapList(data)
          .map(CaixaDisponivelModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final pdvRemoteDataSourceProvider = Provider<PdvRemoteDataSource>((ref) {
  return PdvRemoteDataSourceImpl(ref.watch(dioProvider));
});
