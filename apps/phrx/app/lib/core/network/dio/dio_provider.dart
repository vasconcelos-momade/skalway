import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/connection_notifier.dart';
import '../connectivity/endpoint_resolver.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/tenant_interceptor.dart';

/// Cliente HTTP principal (Dio) com interceptors de auth, tenant e logging.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(activeBaseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  ref.listen(connectionNotifierProvider, (previous, next) {
    dio.options.baseUrl = next.activeBaseUrl;
  });

  dio.interceptors.addAll([
    ref.watch(authInterceptorProvider),
    ref.watch(tenantInterceptorProvider),
    RetryInterceptor(
      dio: dio,
      onCloudFallback: () =>
          ref.read(connectionNotifierProvider.notifier).switchToCloud(),
      onOnline: (mode) =>
          ref.read(connectionNotifierProvider.notifier).setOnline(mode),
      onOffline: () => ref.read(connectionNotifierProvider.notifier).setOffline(),
      readMode: () => ref.read(connectionNotifierProvider).mode,
    ),
    ref.watch(connectivityInterceptorProvider),
    LoggingInterceptor(),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
