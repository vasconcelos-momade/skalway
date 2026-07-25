import 'auth_user.dart';
import 'branch_access.dart';
import 'tenant_access.dart';
import 'central_role.dart';
import '../../../admin/users/domain/entities/user_entities.dart';

/// Estado de sessão central (pós-login, antes/durante a selecção de entidade/unidade).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    required this.tenants,
    this.refreshToken,
    this.tenantId,
    this.branchId,
    this.permissions,
  });

  final String accessToken;
  final String? refreshToken;
  final AuthUser user;
  final List<TenantAccess> tenants;
  final String? tenantId;
  final String? branchId;
  final UserEffectivePermissions? permissions;

  bool get isSuperAdmin => CentralRole.isSuperAdmin(user.role);
  bool get isTenantRole => CentralRole.isTenantRole(user.role);
  bool get isPlatformSession => isSuperAdmin && !hasTenantContext;

  bool get hasTenantContext =>
      tenantId != null &&
      tenantId!.isNotEmpty &&
      branchId != null &&
      branchId!.isNotEmpty;

  bool get requiresTenantSelection =>
      isTenantRole && !hasTenantContext && tenants.isNotEmpty;

  TenantAccess? get selectedTenant {
    if (tenantId == null) return null;
    for (final t in tenants) {
      if (t.id == tenantId) return t;
    }
    return null;
  }

  BranchAccess? get selectedBranch {
    final tenant = selectedTenant;
    if (tenant == null || branchId == null) return null;
    for (final b in tenant.branches) {
      if (b.id == branchId) return b;
    }
    return null;
  }

  AuthSession copyWith({
    String? refreshToken,
    String? tenantId,
    String? branchId,
    UserEffectivePermissions? permissions,
    bool clearTenant = false,
    bool clearPermissions = false,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user,
      tenants: tenants,
      tenantId: clearTenant ? null : (tenantId ?? this.tenantId),
      branchId: clearTenant ? null : (branchId ?? this.branchId),
      permissions: clearPermissions ? null : (permissions ?? this.permissions),
    );
  }
}
