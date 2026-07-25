/// Persistência da chave do carrinho PDV por sessão de caixa.
abstract final class PdvSessionService {
  PdvSessionService._();

  static String cartIdempotencyStorageKey(String userId, String sessaoId) =>
      'pdv_cart_idempotency_${userId}_$sessaoId';

  static String defaultCartIdempotencyKey(String userId, String sessaoId) =>
      'pdv-$userId-$sessaoId';
}
