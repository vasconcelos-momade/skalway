import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/connection_notifier.dart';
import '../../../config/env.dart';
import '../../connectivity/connection_mode.dart';

/// Actualiza estado de conexão após pedidos bem-sucedidos.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._onOnline);

  final void Function(ConnectionMode mode) _onOnline;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final mode = response.requestOptions.baseUrl == Env.apiBaseUrlCloud
        ? ConnectionMode.cloud
        : ConnectionMode.local;
    _onOnline(mode);
    handler.next(response);
  }
}

final connectivityInterceptorProvider = Provider<ConnectivityInterceptor>((ref) {
  return ConnectivityInterceptor(
    (mode) => ref.read(connectionNotifierProvider.notifier).setOnline(mode),
  );
});
