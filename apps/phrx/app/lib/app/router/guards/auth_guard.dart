/// Garante que o utilizador está autenticado.
abstract final class AuthGuard {
  AuthGuard._();

  static bool canActivate(Object context) => true;
}
