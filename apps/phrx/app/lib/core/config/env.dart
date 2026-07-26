import '../contracts/api_envelope.dart';
import 'api_host_resolver.dart';

/// Variáveis de ambiente e segredos de build.
abstract final class Env {
  Env._();

  static String get appName =>
      const String.fromEnvironment('APP_NAME', defaultValue: 'Pharma ERP');

  /// API local (Bun) — LAN, emulador ou localhost. Inclui prefixo `/api/v1`.
  static String get apiBaseUrlLocal =>
      ApiEnvelope.resolveBaseUrl(ApiHostResolver.defaultHost);

  /// API na nuvem usada como alternativa quando o endpoint local falha.
  static String get apiBaseUrlCloud =>
      ApiEnvelope.resolveBaseUrl(ApiHostResolver.defaultCloudHost);
}
