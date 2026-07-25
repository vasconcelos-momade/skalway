import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/api_failure.dart';
import '../../../platform/files/platform_file_delivery.dart';
import 'network_printer_transport.dart';
import 'printer_connection.dart';

/// Serviço de handoff de impressão térmica ESC/POS.
///
/// O backend continua responsável por gerar o payload de impressão.
/// Aqui o Flutter apenas encaminha o payload para a ligação escolhida.
abstract final class ThermalPrinterService {
  ThermalPrinterService._();

  static const MethodChannel _channel = MethodChannel(
    'pharma_erp/thermal_printer',
  );

  static Future<void> printReceipt({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required PrinterConnection connection,
  }) {
    if (connection.isNetwork) {
      return _printOverNetwork(connection, bytes);
    }

    if (connection.isBluetooth) {
      return _printOverBluetooth(connection, bytes, fileName, contentType);
    }

    return PlatformFileDelivery.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  static Future<void> _printOverNetwork(
    PrinterConnection connection,
    Uint8List bytes,
  ) async {
    final host = connection.host?.trim() ?? '';
    if (host.isEmpty) {
      throw const ApiFailure('Impressora de rede sem endereço configurado.');
    }

    try {
      await sendNetworkEscPosBytes(
        host: host,
        port: connection.port,
        bytes: bytes,
      );
    } on UnsupportedError {
      rethrow;
    } catch (e) {
      throw ApiFailure('Falha ao imprimir via rede: $e');
    }
  }

  static Future<void> _printOverBluetooth(
    PrinterConnection connection,
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async {
    if (kIsWeb) {
      await PlatformFileDelivery.downloadBytes(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const ApiFailure(
        'Bluetooth térmico suportado apenas em Android nesta versão.',
      );
    }

    final address = connection.bluetoothAddress?.trim() ?? '';
    if (address.isEmpty) {
      throw const ApiFailure('Impressora Bluetooth sem endereço configurado.');
    }

    try {
      await _channel.invokeMethod<void>('printBluetoothReceipt', <String, dynamic>{
        'address': address,
        'bytes': bytes,
      });
    } on PlatformException catch (e) {
      throw ApiFailure(_mapBluetoothMessage(e));
    } catch (e) {
      throw ApiFailure('Falha ao imprimir via Bluetooth: $e');
    }
  }

  static String _mapBluetoothMessage(PlatformException e) {
    switch (e.code) {
      case 'permission_denied':
        return 'Permissão Bluetooth negada no dispositivo.';
      case 'bluetooth_unavailable':
        return 'Bluetooth indisponível neste dispositivo.';
      case 'bluetooth_disabled':
        return 'Bluetooth desativado. Ative-o para imprimir.';
      case 'printer_not_found':
        return 'Impressora Bluetooth não encontrada entre os dispositivos emparelhados.';
      case 'connection_failed':
        return e.message ?? 'Falha ao ligar à impressora Bluetooth.';
      default:
        return e.message ?? 'Falha ao imprimir via Bluetooth.';
    }
  }

  static Future<void> downloadFallback({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return PlatformFileDelivery.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
