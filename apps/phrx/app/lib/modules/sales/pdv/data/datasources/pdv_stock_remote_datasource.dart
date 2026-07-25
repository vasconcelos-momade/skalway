import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/pdv_stock_validation_model.dart';

abstract class PdvStockRemoteDataSource {
  Future<PdvStockValidationModel> validateProductStock({
    required String productId,
    required int quantity,
  });
}

class PdvStockRemoteDataSourceImpl implements PdvStockRemoteDataSource {
  PdvStockRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PdvStockValidationModel> validateProductStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosValidarDispensacao,
        data: <String, dynamic>{
          'produtoId': productId,
          'quantidade': quantity,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao validar stock.');
      }

      return PdvStockValidationModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final pdvStockRemoteDataSourceProvider = Provider<PdvStockRemoteDataSource>((ref) {
  return PdvStockRemoteDataSourceImpl(ref.watch(dioProvider));
});
