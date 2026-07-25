import '../../../../../core/contracts/pagination_response.dart';
import '../entities/user_entities.dart';

abstract class UserRepository {
  Future<PaginationResponse<TenantUserSummary>> listUsers(UserQuery query);

  Future<UserDashboard> getDashboard();

  Future<TenantUserDetail> getUser(String id);

  Future<TenantUserDetail> createUser(UserFormPayload payload);

  Future<TenantUserDetail> updateUser(String id, UserFormPayload payload);

  Future<void> deleteUser(String id);

  Future<PaginationResponse<UserAuditEntry>> listUserAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<UserEventEntry>> listUserEvents(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<UserEffectivePermissions> getUserEffectivePermissions(String id);

  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions();

  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  );
}

abstract class RoleRepository {
  Future<List<RoleProfile>> listRoles();

  Future<RoleDetail> getRoleDetail(String role);
}

abstract class PermissionRepository {
  Future<List<PermissionMatrixRow>> getMatrix({String? role});

  Future<PermissionDashboard> getPermissionsDashboard();

  Future<void> updateRolePermissions(
    String role,
    List<RolePermissionGrant> grants,
  );

  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  );

  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions();
}
