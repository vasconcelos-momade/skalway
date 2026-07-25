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
    Future.microtask(_restoreMode);
    return ConnectionState();
  }

  Future<void> _restoreMode() async {
    final storedMode =
        await ref.read(secureStorageProvider).readConnectionMode();
    if (storedMode == null) return;

    state = state.copyWith(
      mode: storedMode,
      activeBaseUrl: storedMode == ConnectionMode.cloud
          ? Env.apiBaseUrlCloud
          : Env.apiBaseUrlLocal,
    );
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
