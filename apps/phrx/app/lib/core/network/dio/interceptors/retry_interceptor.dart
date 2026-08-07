import 'package:dio/dio.dart';

import '../../../config/env.dart';
import '../../connectivity/connection_mode.dart';

/// Em falha de ligação, tenta uma vez o endpoint alternativo (local ↔ nuvem).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    required void Function() onCloudFallback,
    required void Function() onLocalFallback,
    required void Function(ConnectionMode mode) onOnline,
    required void Function() onOffline,
    required ConnectionMode Function() readMode,
  })  : _dio = dio,
        _onCloudFallback = onCloudFallback,
        _onLocalFallback = onLocalFallback,
        _onOnline = onOnline,
        _onOffline = onOffline,
        _readMode = readMode;

  final Dio _dio;
  final void Function() _onCloudFallback;
  final void Function() _onLocalFallback;
  final void Function(ConnectionMode mode) _onOnline;
  final void Function() _onOffline;
  final ConnectionMode Function() _readMode;

  static const _retryKey = 'retry_alternate';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final alreadyRetried = extra[_retryKey] == true;

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

    final cloudDistinct = Env.apiBaseUrlCloud != Env.apiBaseUrlLocal;
    if (!cloudDistinct) {
      _onOffline();
      return handler.next(err);
    }

    final mode = _readMode();
    final alternate = mode == ConnectionMode.local
        ? ConnectionMode.cloud
        : ConnectionMode.local;
    final alternateUrl = alternate == ConnectionMode.cloud
        ? Env.apiBaseUrlCloud
        : Env.apiBaseUrlLocal;

    if (alternate == ConnectionMode.cloud) {
      _onCloudFallback();
    } else {
      _onLocalFallback();
    }

    try {
      final response = await _dio.fetch<dynamic>(
        _cloneForAlternate(
          err.requestOptions,
          baseUrl: alternateUrl,
          extra: extra,
        ),
      );
      _onOnline(alternate);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      // Fallback chegou à API: não marcar offline (ex.: 401 de credenciais).
      if (retryError.response != null) {
        _onOnline(alternate);
        return handler.next(retryError);
      }
      _onOffline();
      return handler.next(retryError);
    } catch (_) {
      _onOffline();
    }

    handler.next(err);
  }

  RequestOptions _cloneForAlternate(
    RequestOptions request, {
    required String baseUrl,
    required Map<String, dynamic> extra,
  }) {
    return request.copyWith(
      baseUrl: baseUrl,
      extra: <String, dynamic>{
        ...extra,
        _retryKey: true,
      },
    );
  }
}
