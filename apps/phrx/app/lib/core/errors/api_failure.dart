import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'exceptions.dart';
import 'failures.dart';

enum ApiFailureKind {
  authentication,
  network,
  server,
  validation,
  unknown,
}

class ApiFailure extends Failure {
  const ApiFailure(
    super.message, {
    this.statusCode,
    this.code,
    this.kind = ApiFailureKind.unknown,
  });

  final int? statusCode;
  final String? code;
  final ApiFailureKind kind;

  bool get isAuthentication => kind == ApiFailureKind.authentication;
  bool get isNetwork => kind == ApiFailureKind.network;
  bool get isServer => kind == ApiFailureKind.server;

  /// Converte [DioException] em falha tipada. Nunca trata 401/403 como rede.
  static ApiFailure fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final parsed = _parseBody(response?.data);
    final apiMessage = parsed.message;
    final apiCode = parsed.code;

    _logDiagnostics(error, statusCode: statusCode, apiMessage: apiMessage, apiCode: apiCode);

    if (_isNetworkError(error) && statusCode == null) {
      return const ApiFailure(
        'Sem ligação ao servidor. Verifique a sua ligação à Internet.',
        kind: ApiFailureKind.network,
      );
    }

    if (statusCode == 401 ||
        statusCode == 403 ||
        _isAuthCode(apiCode)) {
      return ApiFailure(
        _authMessage(statusCode: statusCode, code: apiCode, fallback: apiMessage),
        statusCode: statusCode,
        code: apiCode,
        kind: ApiFailureKind.authentication,
      );
    }

    if (statusCode == 400 || statusCode == 422) {
      return ApiFailure(
        apiMessage ?? 'Dados inválidos.',
        statusCode: statusCode,
        code: apiCode,
        kind: ApiFailureKind.validation,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiFailure(
        'Ocorreu um erro no servidor. Tente novamente.',
        statusCode: statusCode,
        code: apiCode,
        kind: ApiFailureKind.server,
      );
    }

    if (apiMessage != null && apiMessage.isNotEmpty) {
      return ApiFailure(
        apiMessage,
        statusCode: statusCode,
        code: apiCode,
      );
    }

    return ApiFailure(
      error.message ?? 'Erro inesperado.',
      statusCode: statusCode,
      code: apiCode,
    );
  }

  /// Lança a excepção tipada correspondente (para camadas que preferem throw).
  Never throwAsException() {
    switch (kind) {
      case ApiFailureKind.authentication:
        throw AuthenticationException(message, statusCode: statusCode, code: code);
      case ApiFailureKind.network:
        throw NetworkException(message);
      case ApiFailureKind.server:
        throw ServerException(message, statusCode: statusCode, code: code);
      case ApiFailureKind.validation:
        throw ValidationException(message, statusCode: statusCode, code: code);
      case ApiFailureKind.unknown:
        throw AppException(message);
    }
  }

  static bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown && error.response == null;
  }

  static bool _isAuthCode(String? code) {
    if (code == null) return false;
    return code == 'AUTH_INVALID_CREDENTIALS' ||
        code == 'AUTH_ACCOUNT_LOCKED' ||
        code == 'AUTH_ACCOUNT_INACTIVE' ||
        code == 'AUTH_UNAUTHORIZED' ||
        code == 'ACCESS_DENIED';
  }

  static String _authMessage({
    required int? statusCode,
    required String? code,
    required String? fallback,
  }) {
    switch (code) {
      case 'AUTH_ACCOUNT_LOCKED':
        return 'A sua conta encontra-se bloqueada.';
      case 'AUTH_ACCOUNT_INACTIVE':
        return 'A sua conta está inativa.';
      case 'AUTH_INVALID_CREDENTIALS':
        return 'Email ou palavra-passe incorretos.';
    }

    final lower = (fallback ?? '').toLowerCase();
    if (lower.contains('bloquead')) {
      return 'A sua conta encontra-se bloqueada.';
    }
    if (lower.contains('inativ') || lower.contains('inactiv')) {
      return 'A sua conta está inativa.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Email ou palavra-passe incorretos.';
    }

    return fallback?.isNotEmpty == true
        ? fallback!
        : 'Email ou palavra-passe incorretos.';
  }

  static ({String? message, String? code}) _parseBody(dynamic data) {
    if (data is! Map) {
      return (message: null, code: null);
    }

    final err = data['error'];
    if (err is Map) {
      final message = err['message'];
      final code = err['code'];
      return (
        message: message is String && message.isNotEmpty ? message : null,
        code: code is String && code.isNotEmpty ? code : null,
      );
    }
    if (err is String && err.isNotEmpty) {
      return (message: err, code: null);
    }
    final message = data['message'];
    return (
      message: message is String && message.isNotEmpty ? message : null,
      code: null,
    );
  }

  static void _logDiagnostics(
    DioException error, {
    required int? statusCode,
    required String? apiMessage,
    required String? apiCode,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Auth/API] status=$statusCode '
      'dioType=${error.type} '
      'apiCode=$apiCode '
      'apiMessage=$apiMessage '
      'exception=${error.error?.runtimeType} '
      'uri=${error.requestOptions.uri}',
    );
  }
}
