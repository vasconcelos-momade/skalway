/// Falhas representáveis na UI (clean architecture).
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

class GenericFailure extends Failure {
  const GenericFailure(super.message);
}
