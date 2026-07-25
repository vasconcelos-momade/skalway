import '../../../../pharmacy/products/domain/entities/product.dart';
import '../entities/pdv_cart.dart';
import '../entities/pdv_checkout.dart';
import '../entities/pdv_service.dart';

abstract class PdvCartRepository {
  Future<PdvCart> getCart({required String userId, required String idempotencyKey});

  Future<PdvCart> addItem({
    required String userId,
    required String idempotencyKey,
    required Product product,
    int quantidade = 1,
  });

  Future<PdvCart> addService({
    required String userId,
    required String idempotencyKey,
    required PdvService service,
    int quantidade = 1,
  });

  Future<PdvCart> incrementItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  });

  Future<PdvCart> decrementItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  });

  Future<PdvCart> removeItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  });

  Future<PdvCheckoutResult> finalizarVenda({
    required String terminalId,
    required String idempotencyKey,
    required PdvPaymentMethod metodoPagamento,
    String? clienteId,
    PdvCheckoutPatient? paciente,
    double? valorRecebido,
  });
}
