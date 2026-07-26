import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging HTTP em modo debug.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    }
    handler.next(err);
  }
}
