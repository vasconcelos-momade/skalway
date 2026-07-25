import '../entities/pdv_stock_validation.dart';

abstract class PdvStockRepository {
  Future<PdvStockValidation> validateProductStock({
    required String productId,
    required int quantity,
  });
}
