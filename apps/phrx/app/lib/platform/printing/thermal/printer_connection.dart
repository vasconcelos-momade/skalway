import 'dart:convert';

enum PrinterConnectionType { bluetooth, network }

class PrinterConnection {
  const PrinterConnection({
    required this.id,
    required this.name,
    required this.type,
    this.bluetoothAddress,
    this.host,
    this.port = 9100,
  });

  const PrinterConnection.bluetooth({
    required this.id,
    required this.name,
    required String this.bluetoothAddress,
  }) : type = PrinterConnectionType.bluetooth,
       host = null,
       port = 9100;

  const PrinterConnection.network({
    required this.id,
    required this.name,
    required String this.host,
    this.port = 9100,
  }) : type = PrinterConnectionType.network,
       bluetoothAddress = null;

  final String id;
  final String name;
  final PrinterConnectionType type;
  final String? bluetoothAddress;
  final String? host;
  final int port;

  String get label => name.trim().isEmpty ? summary : name.trim();

  String get summary {
    return switch (type) {
      PrinterConnectionType.bluetooth =>
        bluetoothAddress?.trim().isNotEmpty == true
            ? 'Bluetooth ${bluetoothAddress!.trim()}'
            : 'Bluetooth',
      PrinterConnectionType.network =>
        host?.trim().isNotEmpty == true
            ? 'Rede ${host!.trim()}:$port'
            : 'Rede',
    };
  }

  bool get isBluetooth => type == PrinterConnectionType.bluetooth;

  bool get isNetwork => type == PrinterConnectionType.network;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      if (bluetoothAddress != null) 'bluetoothAddress': bluetoothAddress,
      if (host != null) 'host': host,
      'port': port,
    };
  }

  String toStorageValue() => jsonEncode(toJson());

  factory PrinterConnection.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']) {
      'bluetooth' => PrinterConnectionType.bluetooth,
      _ => PrinterConnectionType.network,
    };

    return PrinterConnection(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: type,
      bluetoothAddress: json['bluetoothAddress']?.toString(),
      host: json['host']?.toString(),
      port: _toPort(json['port']),
    );
  }

  factory PrinterConnection.fromStorageValue(String value) {
    return PrinterConnection.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }

  static int _toPort(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 9100;
  }
}
