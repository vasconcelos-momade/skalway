/// Papéis central (API) e helpers de routing auth.
abstract final class CentralRole {
  CentralRole._();

  static const superAdmin = 'superadmin';
  static const tenantAdmin = 'admin';
  static const tenantUser = 'usuario';

  static const normalizedSuperAdmin = 'SUPER_ADMIN';
  static const normalizedTenantAdmin = 'TENANT_ADMIN';
  static const normalizedTenantUser = 'TENANT_USER';

  static bool isSuperAdmin(String role) {
    final r = role.toLowerCase();
    return r == superAdmin || r == 'super_admin' || r == normalizedSuperAdmin.toLowerCase();
  }

  static bool isTenantRole(String role) => !isSuperAdmin(role);

  static bool requiresTenantContext(String role) => isTenantRole(role);

  static String normalize(String role) {
    if (isSuperAdmin(role)) return normalizedSuperAdmin;
    final r = role.toLowerCase();
    if (r == tenantAdmin || r == 'tenant_admin') return normalizedTenantAdmin;
    return normalizedTenantUser;
  }
}
