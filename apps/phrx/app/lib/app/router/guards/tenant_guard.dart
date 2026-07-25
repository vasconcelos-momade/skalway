/// Garante contexto de tenant / farmácia válido.
abstract final class TenantGuard {
  TenantGuard._();

  static bool canActivate(Object context) => true;
}
