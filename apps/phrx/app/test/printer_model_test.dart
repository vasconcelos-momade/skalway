import 'package:flutter_test/flutter_test.dart';

import 'package:phrx/modules/settings/data/models/printer_model.dart';
import 'package:phrx/platform/printing/thermal/printer_connection.dart';

void main() {
  group('PrinterDetalheModel', () {
    test('fromJson mapeia campos e nested device/branch', () {
      final model = PrinterDetalheModel.fromJson(<String, dynamic>{
        'id': '12',
        'uuid': 'abc-uuid',
        'name': 'XP-80T Caixa',
        'type': 'ESC_POS',
        'connection': 'NETWORK',
        'ip': '192.168.1.50',
        'port': 9100,
        'model': 'XP-80T',
        'manufacturer': 'Xprinter',
        'active': true,
        'version': 3,
        'device': {'id': '7', 'name': 'POS-01', 'code': 'T1'},
        'branch': {'id': '1', 'code': 'HQ', 'name': 'Matriz'},
      });

      expect(model.id, '12');
      expect(model.deviceId, '7');
      expect(model.branchId, '1');
      expect(model.deviceName, 'POS-01');
      expect(model.branchName, 'Matriz');
      expect(model.version, 3);

      final entity = model.toEntity();
      expect(entity.addressSummary, 'Rede 192.168.1.50:9100');
      expect(entity.isNetwork, isTrue);
    });

    test('toConnection NETWORK devolve PrinterConnection', () {
      final model = PrinterDetalheModel.fromJson(<String, dynamic>{
        'id': '1',
        'name': 'Rede',
        'type': 'ESC_POS',
        'connection': 'NETWORK',
        'ip': '10.0.0.8',
        'port': 9100,
        'active': true,
        'version': 0,
      });

      final connection = model.toConnection();
      expect(connection, isNotNull);
      expect(connection!.type, PrinterConnectionType.network);
      expect(connection.host, '10.0.0.8');
      expect(connection.port, 9100);
    });

    test('toConnection PDF devolve null', () {
      final model = PrinterDetalheModel.fromJson(<String, dynamic>{
        'id': '2',
        'name': 'PDF',
        'type': 'A4',
        'connection': 'PDF',
        'active': true,
        'version': 0,
      });
      expect(model.toConnection(), isNull);
    });

    test('toConnection BLUETOOTH usa ip como endereço', () {
      final model = PrinterDetalheModel.fromJson(<String, dynamic>{
        'id': '3',
        'name': 'BT',
        'type': 'ESC_POS',
        'connection': 'BLUETOOTH',
        'ip': '00:11:22:33:44:55',
        'active': true,
        'version': 0,
      });
      final connection = model.toConnection();
      expect(connection?.type, PrinterConnectionType.bluetooth);
      expect(connection?.bluetoothAddress, '00:11:22:33:44:55');
    });
  });
}
