import 'package:dio/dio.dart';

import 'failures.dart';

class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.statusCode});

  final int? statusCode;

  static ApiFailure fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    String message = error.message ?? 'Erro de rede';

    var parsedFromBody = false;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        final nested = err['message'];
        if (nested is String && nested.isNotEmpty) {
          message = nested;
          parsedFromBody = true;
        }
      } else if (err is String && err.isNotEmpty) {
        message = err;
        parsedFromBody = true;
      } else if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
        parsedFromBody = true;
      }
    }
    if (!parsedFromBody && response?.statusCode == 401) {
      message = 'Credenciais inválidas ou sessão expirada.';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Tempo de ligação esgotado. Verifique a rede ou o servidor local.';
    } else if (error.type == DioExceptionType.connectionError) {
      final target = error.requestOptions.uri;
      message =
          'Sem ligação ao servidor ($target). Verifique se a API está activa e se o URL corresponde a este dispositivo.';
    }

    return ApiFailure(message, statusCode: response?.statusCode);
  }
}
