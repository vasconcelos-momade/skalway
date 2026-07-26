import '../errors/failures.dart';

/// Normalização de erros para UI e relatórios.
abstract final class ErrorHandler {
  ErrorHandler._();

  static String messageFor(Failure failure) => failure.message;
}
