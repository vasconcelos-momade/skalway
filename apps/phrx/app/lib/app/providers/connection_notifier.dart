import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/connectivity/connection_mode.dart';
import '../../core/network/connectivity/connection_status.dart';
import '../../core/security/secure_storage_service.dart';

class ConnectionState {
  ConnectionState({
    this.mode = ConnectionMode.local,
    this.status = ConnectionStatus.unknown,
    String? activeBaseUrl,
  }) : activeBaseUrl = activeBaseUrl ?? Env.apiBaseUrlLocal;

  final ConnectionMode mode;
  final ConnectionStatus status;
  final String activeBaseUrl;

  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;

  ConnectionState copyWith({
    ConnectionMode? mode,
    ConnectionStatus? status,
    String? activeBaseUrl,
  }) {
    return ConnectionState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      activeBaseUrl: activeBaseUrl ?? this.activeBaseUrl,
    );
  }
}

class ConnectionNotifier extends Notifier<ConnectionState> {
  @override
  ConnectionState build() {
    Future.microtask(_bootstrapConnectivity);
    return ConnectionState();
  }

  /// Preferir o endpoint local quando estiver acessível (Docker local em DEV).
  /// Evita ficar preso em "modo nuvem" gravado após um fallback antigo.
  Future<void> _bootstrapConnectivity() async {
    final storedMode =
        await ref.read(secureStorageProvider).readConnectionMode();

    final localOk = await _pingHealth(Env.apiBaseUrlLocal);
    if (localOk) {
      state = state.copyWith(
        mode: ConnectionMode.local,
        status: ConnectionStatus.online,
        activeBaseUrl: Env.apiBaseUrlLocal,
      );
      _persistMode(ConnectionMode.local);
      return;
    }

    final cloudDistinct = Env.apiBaseUrlCloud != Env.apiBaseUrlLocal;
    if (cloudDistinct) {
      final cloudOk = await _pingHealth(Env.apiBaseUrlCloud);
      if (cloudOk) {
        state = state.copyWith(
          mode: ConnectionMode.cloud,
          status: ConnectionStatus.online,
          activeBaseUrl: Env.apiBaseUrlCloud,
        );
        _persistMode(ConnectionMode.cloud);
        return;
      }
    }

    final mode = storedMode ?? ConnectionMode.local;
    state = state.copyWith(
      mode: mode,
      status: ConnectionStatus.offline,
      activeBaseUrl: mode == ConnectionMode.cloud
          ? Env.apiBaseUrlCloud
          : Env.apiBaseUrlLocal,
    );
  }

  Future<bool> _pingHealth(String baseUrl) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        headers: const <String, dynamic>{'Accept': 'application/json'},
      ),
    );
    try {
      final response = await dio.get<dynamic>('/health');
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 500;
    } on DioException catch (e) {
      // Qualquer resposta HTTP prova que o host está acessível.
      return e.response != null;
    } catch (_) {
      return false;
    } finally {
      dio.close();
    }
  }

  void setOnline(ConnectionMode mode) {
    state = state.copyWith(
      status: ConnectionStatus.online,
      mode: mode,
      activeBaseUrl: mode == ConnectionMode.cloud
          ? Env.apiBaseUrlCloud
          : Env.apiBaseUrlLocal,
    );
    _persistMode(mode);
  }

  void setOffline() {
    state = state.copyWith(status: ConnectionStatus.offline);
  }

  void switchToCloud() {
    state = state.copyWith(
      mode: ConnectionMode.cloud,
      activeBaseUrl: Env.apiBaseUrlCloud,
    );
    _persistMode(ConnectionMode.cloud);
  }

  void switchToLocal() {
    state = state.copyWith(
      mode: ConnectionMode.local,
      activeBaseUrl: Env.apiBaseUrlLocal,
    );
    _persistMode(ConnectionMode.local);
  }

  void _persistMode(ConnectionMode mode) {
    ref.read(secureStorageProvider).writeConnectionMode(mode);
  }
}

final connectionNotifierProvider =
    NotifierProvider<ConnectionNotifier, ConnectionState>(ConnectionNotifier.new);
