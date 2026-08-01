import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/connection_notifier.dart';
import '../../../config/env.dart';
import '../../connectivity/connection_mode.dart';

/// Actualiza estado de conexão após contacto real com a API (sucesso ou erro HTTP).
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._onOnline);

  final void Function(ConnectionMode mode) _onOnline;

  void _markOnline(RequestOptions options) {
    final mode = options.baseUrl == Env.apiBaseUrlCloud
        ? ConnectionMode.cloud
        : ConnectionMode.local;
    _onOnline(mode);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _markOnline(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Qualquer resposta HTTP prova que a API está acessível (ex.: 401 de login).
    if (err.response != null) {
      _markOnline(err.requestOptions);
    }
    handler.next(err);
  }
}

final connectivityInterceptorProvider = Provider<ConnectivityInterceptor>((ref) {
  return ConnectivityInterceptor(
    (mode) => ref.read(connectionNotifierProvider.notifier).setOnline(mode),
  );
});
