/// Verificação de permissões de utilizador / papéis.
abstract final class PermissionManager {
  PermissionManager._();

  static bool can(String permission) => true;
}
