import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/movimentacao.dart';
import '../models/movimentacao_model.dart';

abstract class MovimentacaoRemoteDataSource {
  Future<MovimentacoesPageResultModel> listarMovimentacoes(
    MovimentacaoQuery query,
  );
}

class MovimentacaoRemoteDataSourceImpl implements MovimentacaoRemoteDataSource {
  MovimentacaoRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<MovimentacoesPageResultModel> listarMovimentacoes(
    MovimentacaoQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantStockMovements,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
          if (query.tipo != null) 'tipo': query.tipo,
          if (query.origem != null) 'origem': query.origem,
          if (query.dataInicio != null)
            'dataInicio': _formatApiDate(query.dataInicio!),
          if (query.dataFim != null) 'dataFim': _formatApiDate(query.dataFim!),
        },
      );

      final data = response.data;
      if (data == null) {
        return MovimentacoesPageResultModel.fromJson(const <String, dynamic>{});
      }

      final payload = ApiEnvelope.unwrapMap(data);
      return MovimentacoesPageResultModel.fromJson(payload);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _formatApiDate(DateTime value) {
    final year = value.year;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

final movimentacaoRemoteDataSourceProvider =
    Provider<MovimentacaoRemoteDataSource>((ref) {
      return MovimentacaoRemoteDataSourceImpl(ref.watch(dioProvider));
    });
