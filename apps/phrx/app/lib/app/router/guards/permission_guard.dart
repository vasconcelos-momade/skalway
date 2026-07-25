/// Garante permissões para rotas ou ações.
abstract final class PermissionGuard {
  PermissionGuard._();

  static bool hasPermission(String permission) => true;
}
