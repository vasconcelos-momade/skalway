import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../domain/entities/printer.dart';

class PrinterDetalheModel {
  const PrinterDetalheModel({
    required this.id,
    required this.name,
    required this.type,
    required this.connection,
    this.uuid,
    this.ip,
    this.port,
    this.model,
    this.manufacturer,
    this.active = true,
    this.version = 0,
    this.deviceId,
    this.branchId,
    this.deviceName,
    this.branchName,
  });

  final String id;
  final String? uuid;
  final String name;
  final String type;
  final String connection;
  final String? ip;
  final int? port;
  final String? model;
  final String? manufacturer;
  final bool active;
  final int version;
  final String? deviceId;
  final String? branchId;
  final String? deviceName;
  final String? branchName;

  factory PrinterDetalheModel.fromJson(Map<String, dynamic> json) {
    final device = json['device'];
    final branch = json['branch'];
    return PrinterDetalheModel(
      id: json['id']?.toString() ?? '',
      uuid: _nullableString(json['uuid']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ESC_POS',
      connection: json['connection']?.toString() ?? 'NETWORK',
      ip: _nullableString(json['ip']),
      port: _toPort(json['port']),
      model: _nullableString(json['model']),
      manufacturer: _nullableString(json['manufacturer']),
      active: json['active'] == true || json['active'] == 1,
      version: _toInt(json['version']),
      deviceId: device is Map<String, dynamic>
          ? device['id']?.toString()
          : json['deviceId']?.toString(),
      branchId: branch is Map<String, dynamic>
          ? branch['id']?.toString()
          : json['branchId']?.toString(),
      deviceName: device is Map<String, dynamic>
          ? _nullableString(device['name'])
          : null,
      branchName: branch is Map<String, dynamic>
          ? _nullableString(branch['name'])
          : null,
    );
  }

  PrinterDetalhe toEntity() {
    return PrinterDetalhe(
      id: id,
      uuid: uuid,
      name: name,
      type: type,
      connection: connection,
      ip: ip,
      port: port,
      model: model,
      manufacturer: manufacturer,
      active: active,
      version: version,
      deviceId: deviceId,
      branchId: branchId,
      deviceName: deviceName,
      branchName: branchName,
    );
  }

  /// Maps API printer to local thermal transport when possible.
  PrinterConnection? toConnection() {
    switch (connection) {
      case 'NETWORK':
        final host = ip?.trim();
        if (host == null || host.isEmpty) return null;
        return PrinterConnection.network(
          id: id,
          name: name,
          host: host,
          port: port ?? 9100,
        );
      case 'BLUETOOTH':
        final address = ip?.trim();
        if (address == null || address.isEmpty) return null;
        return PrinterConnection.bluetooth(
          id: id,
          name: name,
          bluetoothAddress: address,
        );
      default:
        return null;
    }
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toPort(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
