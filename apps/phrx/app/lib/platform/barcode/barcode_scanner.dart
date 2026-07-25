import 'package:flutter/widgets.dart';

import 'barcode_scanner_io.dart' as impl_io;
import 'barcode_scanner_web.dart' as impl_web;

/// Leitura de códigos de barras (câmara / hardware).
///
/// Mantém a camada `platform/` fina: módulos chamam `BarcodeScanner.scan()`
/// e recebem o código (ou null se cancelado/indisponível).
abstract final class BarcodeScanner {
  BarcodeScanner._();

  static Future<String?> scan(BuildContext context) {
    // Prefer IO implementation when available; web returns null.
    // (Imports are always present; on web we avoid referencing IO code paths.)
    try {
      // ignore: avoid_dynamic_calls
      return (impl_io.scanImplFromContext)(context);
    } catch (_) {
      // ignore: avoid_dynamic_calls
      return (impl_web.scanImplFromContext)(context);
    }
  }
}
