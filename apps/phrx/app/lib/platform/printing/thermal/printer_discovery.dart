import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import 'printer_connection.dart';

class PrinterDiscoveryService {
  PrinterDiscoveryService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_thermalPrinterChannelName);

  final MethodChannel _channel;

  Future<List<PrinterConnection>> listBluetoothPrinters() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const <PrinterConnection>[];
    }

    try {
      final raw = await _channel.invokeListMethod<dynamic>(
        'getPairedBluetoothPrinters',
      );
      if (raw == null) {
        return const <PrinterConnection>[];
      }

      return raw.whereType<Map<dynamic, dynamic>>().map((entry) {
        final id = entry['id']?.toString() ?? entry['address']?.toString() ?? '';
        final address = entry['address']?.toString() ?? '';
        return PrinterConnection.bluetooth(
          id: id,
          name: entry['name']?.toString() ?? 'Impressora Bluetooth',
          bluetoothAddress: address,
        );
      }).toList(growable: false);
    } on PlatformException catch (e) {
      throw ApiFailure(_mapPlatformMessage(e));
    } catch (e) {
      throw ApiFailure('Falha ao listar impressoras Bluetooth: $e');
    }
  }

  String _mapPlatformMessage(PlatformException e) {
    switch (e.code) {
      case 'permission_denied':
        return 'Permissão Bluetooth negada no dispositivo.';
      case 'bluetooth_unavailable':
        return 'Bluetooth indisponível neste dispositivo.';
      case 'bluetooth_disabled':
        return 'Bluetooth desativado. Ative-o para imprimir.';
      default:
        return e.message ?? 'Falha ao descobrir impressoras Bluetooth.';
    }
  }
}

const String _thermalPrinterChannelName = 'pharma_erp/thermal_printer';

final printerDiscoveryProvider = Provider<PrinterDiscoveryService>(
  (ref) => PrinterDiscoveryService(),
);
