/// Exceções lançadas pela aplicação (camada de dados / domínio).
class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

/// Credenciais inválidas, conta bloqueada/inactiva ou sessão não autorizada.
class AuthenticationException extends AppException {
  const AuthenticationException(
    String message, {
    this.statusCode,
    this.code,
    Object? cause,
  }) : super(message, cause);

  final int? statusCode;
  final String? code;
}

/// Timeout, DNS, connection refused ou ausência de resposta HTTP.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Erro interno do servidor (5xx).
class ServerException extends AppException {
  const ServerException(
    String message, {
    this.statusCode,
    this.code,
    Object? cause,
  }) : super(message, cause);

  final int? statusCode;
  final String? code;
}

/// Dados de pedido inválidos (400/422).
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    this.statusCode,
    this.code,
    Object? cause,
  }) : super(message, cause);

  final int? statusCode;
  final String? code;
}
