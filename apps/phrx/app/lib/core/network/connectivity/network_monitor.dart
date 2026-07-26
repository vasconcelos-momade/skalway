import 'connection_status.dart';

/// Observa mudanças de rede ao longo do tempo.
abstract final class NetworkMonitor {
  NetworkMonitor._();

  static Stream<ConnectionStatus> get changes => const Stream.empty();
}
