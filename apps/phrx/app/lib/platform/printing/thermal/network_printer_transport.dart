import 'network_printer_transport_stub.dart'
    if (dart.library.io) 'network_printer_transport_io.dart' as impl;

Future<void> sendNetworkEscPosBytes({
  required String host,
  required int port,
  required List<int> bytes,
}) {
  return impl.sendNetworkEscPosBytesImpl(
    host: host,
    port: port,
    bytes: bytes,
  );
}
