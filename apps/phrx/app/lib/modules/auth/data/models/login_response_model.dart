import '../../domain/entities/auth_user.dart';
import '../../domain/entities/branch_access.dart';
import '../../domain/entities/tenant_access.dart';
import '../../../admin/users/domain/entities/user_entities.dart';
import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../domain/entities/central_role.dart';

class LoginResponseModel {
  LoginResponseModel({
    required this.accessToken,
    required this.user,
    required this.tenants,
    required this.role,
    required this.redirectTo,
    this.tenantId,
    this.branchId,
    this.permissions,
    this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final tenantsRaw = json['tenants'];
    final tenantsList = tenantsRaw is List
        ? tenantsRaw
            .whereType<Map<String, dynamic>>()
            .map(TenantAccessModel.fromJson)
            .toList()
        : <TenantAccess>[];

    final user = AuthUserModel.fromJson(json['user'] as Map<String, dynamic>);
    final role = json['role'] as String? ?? CentralRole.normalize(user.role);
    final tenantId = json['tenantId'] as String?;
    final branchId = json['branchId'] as String?;

    UserEffectivePermissions? permissions;
    final permsRaw = json['permissions'];
    if (permsRaw is List && permsRaw.isNotEmpty) {
      permissions = UserEffectivePermissions(
        userId: user.id,
        role: role,
        permissions: permsRaw
            .whereType<Map<String, dynamic>>()
            .map(UserEffectivePermission.fromJson)
            .toList(),
      );
    }

    final claimedRedirect = json['redirectTo'] as String?;
    final redirectTo = _resolveRedirect(
      claimed: claimedRedirect,
      role: role,
      tenantId: tenantId,
      tenants: tenantsList,
      permissions: permissions,
    );

    // Compatibilidade com resposta antiga (`auth` aninhado).
    final authRaw = json['auth'];
    if (authRaw is Map<String, dynamic>) {
      final nestedRole = authRaw['normalizedRole'] as String? ?? role;
      return LoginResponseModel(
        accessToken: (json['accessToken'] ?? json['token']) as String,
        user: user,
        tenants: tenantsList,
        role: nestedRole,
        tenantId: tenantId,
        branchId: branchId,
        redirectTo: _resolveRedirect(
          claimed: authRaw['redirectTo'] as String? ?? claimedRedirect,
          role: nestedRole,
          tenantId: tenantId,
          tenants: tenantsList,
          permissions: permissions,
        ),
        permissions: permissions,
        refreshToken: json['refreshToken'] as String?,
      );
    }

    return LoginResponseModel(
      accessToken: (json['accessToken'] ?? json['token']) as String,
      user: user,
      tenants: tenantsList,
      role: role,
      tenantId: tenantId,
      branchId: branchId,
      redirectTo: redirectTo,
      permissions: permissions,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  static String _resolveRedirect({
    required String? claimed,
    required String role,
    required String? tenantId,
    required List<TenantAccess> tenants,
    UserEffectivePermissions? permissions,
  }) {
    if (CentralRole.isSuperAdmin(role)) {
      return AppRoutePaths.authAccessSelection;
    }

    final hasTenant = tenantId != null && tenantId.isNotEmpty;
    if (!hasTenant) {
      final single = tenants.length == 1 && tenants.first.branches.length == 1;
      if (!single) return AppRoutePaths.authBranchSelection;
    }

    if (permissions != null) {
      return homePathForPermissions(permissions);
    }

    return claimed ??
        _inferRedirect(role: role, tenantId: tenantId, tenants: tenants);
  }

  static String _inferRedirect({
    required String role,
    required String? tenantId,
    required List<TenantAccess> tenants,
  }) {
    if (CentralRole.isSuperAdmin(role)) {
      return AppRoutePaths.authAccessSelection;
    }
    if (tenantId != null && tenantId.isNotEmpty) {
      return AppRoutePaths.dashboard;
    }
    final single = tenants.length == 1 && tenants.first.branches.length == 1;
    return single ? AppRoutePaths.dashboard : AppRoutePaths.authBranchSelection;
  }

  final String accessToken;
  final String? refreshToken;
  final AuthUser user;
  final List<TenantAccess> tenants;
  final String role;
  final String? tenantId;
  final String? branchId;
  final String redirectTo;
  final UserEffectivePermissions? permissions;
}

class AuthUserModel {
  static AuthUser fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'usuario',
    );
  }
}

class TenantAccessModel {
  static TenantAccess fromJson(Map<String, dynamic> json) {
    final branchesRaw = json['branches'];
    final branches = branchesRaw is List
        ? branchesRaw
            .whereType<Map<String, dynamic>>()
            .map(BranchAccessModel.fromJson)
            .toList()
        : <BranchAccess>[];

    return TenantAccess(
      id: '${json['id']}',
      tenantKey: json['tenantKey'] as String? ?? json['name'] as String? ?? '',
      tenantName:
          json['tenantName'] as String? ?? json['companyName'] as String? ?? '',
      branches: branches,
    );
  }
}

class BranchAccessModel {
  static BranchAccess fromJson(Map<String, dynamic> json) {
    return BranchAccess(
      id: '${json['id']}',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
