import 'dart:typed_data';

import 'platform_file_delivery_stub.dart'
    if (dart.library.io) 'platform_file_delivery_io.dart'
    if (dart.library.html) 'platform_file_delivery_web.dart' as impl;

/// Entrega de ficheiros binários ao utilizador (preview ou download).
abstract final class PlatformFileDelivery {
  PlatformFileDelivery._();

  static Future<void> openBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return impl.openBytesImpl(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  static Future<void> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return impl.downloadBytesImpl(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
