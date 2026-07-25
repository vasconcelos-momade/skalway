import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_storage_service.dart';
import '../../../platform/printing/thermal/printer_connection.dart';
import '../data/datasources/printer_remote_datasource.dart';
import '../data/models/printer_model.dart';
import '../domain/entities/printer.dart';

/// Resolves the default thermal printer for PDV/invoice printing.
///
/// Prefers the locally cached default (secure storage). If missing, falls back
/// to the first active NETWORK/BLUETOOTH printer from the API and caches it.
class DefaultPrinterService {
  DefaultPrinterService({
    required SecureStorageService storage,
    required PrinterRemoteDataSource remote,
  })  : _storage = storage,
        _remote = remote;

  final SecureStorageService _storage;
  final PrinterRemoteDataSource _remote;

  Future<PrinterConnection?> resolveConnection() async {
    final cached = await _readCached();
    if (cached != null) return cached;

    final fromApi = await _fetchPreferredFromApi();
    if (fromApi == null) return null;

    final connection = fromApi.toConnection();
    if (connection != null) {
      await _storage.writeThermalPrinterDefault(connection.toStorageValue());
    }
    return connection;
  }

  Future<void> setDefault(PrinterDetalhe printer) async {
    final model = PrinterDetalheModel(
      id: printer.id,
      uuid: printer.uuid,
      name: printer.name,
      type: printer.type,
      connection: printer.connection,
      ip: printer.ip,
      port: printer.port,
      model: printer.model,
      manufacturer: printer.manufacturer,
      active: printer.active,
      version: printer.version,
      deviceId: printer.deviceId,
      branchId: printer.branchId,
      deviceName: printer.deviceName,
      branchName: printer.branchName,
    );
    final connection = model.toConnection();
    if (connection == null) {
      throw StateError(
        'Impressora ${printer.name} não tem ligação local (NETWORK/BLUETOOTH).',
      );
    }
    await _storage.writeThermalPrinterDefault(connection.toStorageValue());
  }

  Future<String?> readDefaultPrinterId() async {
    final cached = await _readCached();
    return cached?.id;
  }

  Future<void> clearDefault() => _storage.writeThermalPrinterDefault(null);

  Future<PrinterConnection?> _readCached() async {
    final raw = await _storage.readThermalPrinterDefault();
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return PrinterConnection.fromStorageValue(raw);
    } catch (_) {
      return null;
    }
  }

  Future<PrinterDetalheModel?> _fetchPreferredFromApi() async {
    try {
      final response = await _remote.search(
        page: 1,
        pageSize: 50,
        active: true,
      );
      for (final item in response.items) {
        if (item.toConnection() != null) return item;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

final defaultPrinterServiceProvider = Provider<DefaultPrinterService>(
  (ref) => DefaultPrinterService(
    storage: ref.watch(secureStorageProvider),
    remote: ref.watch(printerRemoteDataSourceProvider),
  ),
);
