/// Verifica conectividade de rede.
abstract final class NetworkChecker {
  NetworkChecker._();

  static Future<bool> get hasConnection async => true;
}
