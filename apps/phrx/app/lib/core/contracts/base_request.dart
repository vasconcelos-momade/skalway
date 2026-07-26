/// Pedido HTTP base (query/body comuns).
abstract class BaseRequest {
  const BaseRequest();

  Map<String, dynamic> toJson();
}
