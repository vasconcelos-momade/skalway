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
      final data = err.response?.data;
      String? apiMessage;
      String? apiCode;
      if (data is Map) {
        final error = data['error'];
        if (error is Map) {
          apiMessage = error['message']?.toString();
          apiCode = error['code']?.toString();
        }
      }
      debugPrint(
        '[HTTP] ERROR status=${err.response?.statusCode} '
        'type=${err.type} '
        'code=$apiCode '
        'message=$apiMessage '
        'uri=${err.requestOptions.uri}',
      );
    }
    handler.next(err);
  }
}
