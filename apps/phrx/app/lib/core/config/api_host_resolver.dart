import 'package:flutter/foundation.dart';

/// Host da API sem prefixo `/api/v1`.
///
/// O backend escuta na porta 3300 dentro do container, mas no ambiente local a
/// porta exposta para browser/desktop/emulador é 4001.
abstract final class ApiHostResolver {
  ApiHostResolver._();

  static const int defaultPort = 4001;

  /// Valor de `--dart-define=API_BASE_URL=...` ou host por plataforma.
  static String get defaultHost {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return _platformDefaultHost();
  }

  static String get defaultCloudHost {
    const fromDefine = String.fromEnvironment('API_CLOUD_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return defaultHost;
  }

  static String _platformDefaultHost() {
    if (kIsWeb) {
      // No browser, 127.0.0.1 aponta para a máquina do utilizador.
      // Usamos o host actual (onde o web app está a correr) e a porta da API.
      final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return '$scheme://$host:$defaultPort';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulador Android: localhost do host é 10.0.2.2
        return 'http://10.0.2.2:$defaultPort';
      default:
        return 'http://127.0.0.1:$defaultPort';
    }
  }

  /// Dica curta para o ecrã de login quando a ligação falha.
  /// Usa o host efectivo (dart-define ou fallback por plataforma).
  static String connectionHintForPlatform() {
    final host = defaultHost;
    final cloud = defaultCloudHost;
    if (kIsWeb) {
      return 'Web: API em $host. Ajuste com --dart-define=API_BASE_URL=... se necessário.';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android: API em $host'
            '${cloud != host ? ' (nuvem: $cloud)' : ''}.';
      default:
        return 'Desktop: API em $host'
            '${cloud != host ? ' (nuvem: $cloud)' : ''}.';
    }
  }
}
