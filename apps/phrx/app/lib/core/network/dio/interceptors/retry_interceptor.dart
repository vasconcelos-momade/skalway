import 'package:dio/dio.dart';

import '../../../config/env.dart';
import '../../connectivity/connection_mode.dart';

/// Tenta novamente uma vez em caso de falha de ligação; opcionalmente alterna para a API na nuvem.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    required void Function() onCloudFallback,
    required void Function(ConnectionMode mode) onOnline,
    required void Function() onOffline,
    required ConnectionMode Function() readMode,
  })  : _dio = dio,
        _onCloudFallback = onCloudFallback,
        _onOnline = onOnline,
        _onOffline = onOffline,
        _readMode = readMode;

  final Dio _dio;
  final void Function() _onCloudFallback;
  final void Function(ConnectionMode mode) _onOnline;
  final void Function() _onOffline;
  final ConnectionMode Function() _readMode;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final alreadyRetried = extra['retry_cloud'] == true;

    // Respostas HTTP (incl. 401/403/500) nunca são falhas de conectividade.
    if (err.response != null) {
      return handler.next(err);
    }

    final isConnection = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (!isConnection || alreadyRetried) {
      return handler.next(err);
    }

    if (_readMode() == ConnectionMode.local &&
        Env.apiBaseUrlCloud != Env.apiBaseUrlLocal) {
      _onCloudFallback();
      try {
        final response = await _dio.fetch<dynamic>(
          _cloneForCloudRetry(
            err.requestOptions,
            extra: extra,
          ),
        );
        _onOnline(ConnectionMode.cloud);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        // Fallback chegou à API: não marcar offline (ex.: 401 de credenciais).
        if (retryError.response != null) {
          _onOnline(ConnectionMode.cloud);
          return handler.next(retryError);
        }
        _onOffline();
        return handler.next(retryError);
      } catch (_) {
        _onOffline();
      }
    }

    _onOffline();
    handler.next(err);
  }

  RequestOptions _cloneForCloudRetry(
    RequestOptions request, {
    required Map<String, dynamic> extra,
  }) {
    return request.copyWith(
      baseUrl: Env.apiBaseUrlCloud,
      extra: <String, dynamic>{
        ...extra,
        'retry_cloud': true,
      },
    );
  }
}
