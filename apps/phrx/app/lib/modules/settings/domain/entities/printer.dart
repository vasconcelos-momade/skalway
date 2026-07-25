class PrinterDetalhe {
  const PrinterDetalhe({
    required this.id,
    required this.name,
    required this.type,
    required this.connection,
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
    this.uuid,
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

  bool get isNetwork => connection == 'NETWORK';
  bool get isBluetooth => connection == 'BLUETOOTH';
  bool get isPdf => connection == 'PDF';

  String get addressSummary {
    if (isNetwork) {
      final host = ip?.trim();
      if (host == null || host.isEmpty) return 'Rede';
      return 'Rede $host:${port ?? 9100}';
    }
    if (isBluetooth) {
      final address = ip?.trim();
      if (address == null || address.isEmpty) return 'Bluetooth';
      return 'Bluetooth $address';
    }
    if (isPdf) return 'PDF';
    if (connection == 'USB') return 'USB';
    return connection;
  }
}
