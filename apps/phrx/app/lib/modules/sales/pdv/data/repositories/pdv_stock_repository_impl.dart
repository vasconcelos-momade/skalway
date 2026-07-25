import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pdv_stock_validation.dart';
import '../../domain/repositories/pdv_stock_repository.dart';
import '../datasources/pdv_stock_remote_datasource.dart';
import '../models/pdv_stock_validation_model.dart';

class PdvStockRepositoryImpl implements PdvStockRepository {
  PdvStockRepositoryImpl(this._remoteDataSource);

  final PdvStockRemoteDataSource _remoteDataSource;

  @override
  Future<PdvStockValidation> validateProductStock({
    required String productId,
    required int quantity,
  }) async {
    final response = await _remoteDataSource.validateProductStock(
      productId: productId,
      quantity: quantity,
    );
    return _toEntity(response);
  }

  PdvStockValidation _toEntity(PdvStockValidationModel model) {
    return PdvStockValidation(
      canAdd: model.canAdd,
      maximumAllowedQuantity: model.maximumAllowedQuantity,
      mensagem: model.mensagem,
    );
  }
}

final pdvStockRepositoryProvider = Provider<PdvStockRepository>((ref) {
  return PdvStockRepositoryImpl(ref.watch(pdvStockRemoteDataSourceProvider));
});
