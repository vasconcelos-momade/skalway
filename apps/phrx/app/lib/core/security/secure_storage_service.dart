import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_constants.dart';
import '../network/connectivity/connection_mode.dart';

/// Persistência segura de tokens e contexto multi-inquilino.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: StorageConstants.accessToken, value: token);

  Future<String?> readAccessToken() =>
      _storage.read(key: StorageConstants.accessToken);

  Future<void> writeRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: StorageConstants.refreshToken);
      return;
    }
    await _storage.write(key: StorageConstants.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageConstants.refreshToken);

  Future<void> writeUserJson(String json) =>
      _storage.write(key: StorageConstants.userJson, value: json);

  Future<String?> readUserJson() => _storage.read(key: StorageConstants.userJson);

  Future<void> writeTenantsJson(String json) =>
      _storage.write(key: StorageConstants.tenantsJson, value: json);

  Future<String?> readTenantsJson() =>
      _storage.read(key: StorageConstants.tenantsJson);

  Future<void> writeTenantId(String? id) async {
    if (id == null) {
      await _storage.delete(key: StorageConstants.tenantId);
      return;
    }
    await _storage.write(key: StorageConstants.tenantId, value: id);
  }

  Future<String?> readTenantId() => _storage.read(key: StorageConstants.tenantId);

  Future<void> writeBranchId(String? id) async {
    if (id == null) {
      await _storage.delete(key: StorageConstants.branchId);
      return;
    }
    await _storage.write(key: StorageConstants.branchId, value: id);
  }

  Future<String?> readBranchId() => _storage.read(key: StorageConstants.branchId);

  Future<void> writeConnectionMode(ConnectionMode mode) => _storage.write(
        key: StorageConstants.connectionMode,
        value: mode.name,
      );

  Future<ConnectionMode?> readConnectionMode() async {
    final raw = await _storage.read(key: StorageConstants.connectionMode);
    return switch (raw) {
      'local' => ConnectionMode.local,
      'cloud' => ConnectionMode.cloud,
      _ => null,
    };
  }

  Future<void> writeApiKeyLocal(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      await _storage.delete(key: StorageConstants.apiKeyLocal);
      return;
    }
    await _storage.write(key: StorageConstants.apiKeyLocal, value: apiKey);
  }

  Future<String?> readApiKeyLocal() =>
      _storage.read(key: StorageConstants.apiKeyLocal);

  Future<void> writeApiKeyCloud(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      await _storage.delete(key: StorageConstants.apiKeyCloud);
      return;
    }
    await _storage.write(key: StorageConstants.apiKeyCloud, value: apiKey);
  }

  Future<String?> readApiKeyCloud() =>
      _storage.read(key: StorageConstants.apiKeyCloud);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: StorageConstants.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    await _storage.write(key: StorageConstants.deviceId, value: id);
    return id;
  }

  Future<void> writeThermalPrinterDefault(String? json) async {
    if (json == null || json.isEmpty) {
      await _storage.delete(key: StorageConstants.thermalPrinterDefault);
      return;
    }
    await _storage.write(key: StorageConstants.thermalPrinterDefault, value: json);
  }

  Future<String?> readThermalPrinterDefault() =>
      _storage.read(key: StorageConstants.thermalPrinterDefault);

  Future<void> clearAuth() async {
    await Future.wait<void>([
      _storage.delete(key: StorageConstants.accessToken),
      _storage.delete(key: StorageConstants.refreshToken),
      _storage.delete(key: StorageConstants.userJson),
      _storage.delete(key: StorageConstants.tenantsJson),
      _storage.delete(key: StorageConstants.tenantId),
      _storage.delete(key: StorageConstants.branchId),
      _storage.delete(key: StorageConstants.connectionMode),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
