import 'dart:async';
import 'dart:io';

Future<void> sendNetworkEscPosBytesImpl({
  required String host,
  required int port,
  required List<int> bytes,
}) async {
  final socket = await Socket.connect(
    host,
    port,
    timeout: const Duration(seconds: 5),
  );

  try {
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  } finally {
    unawaited(socket.done.catchError((_) {}));
    socket.destroy();
  }
}
