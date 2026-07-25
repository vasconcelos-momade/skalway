import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/user_entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remote);

  final UserRemoteDataSource _remote;

  @override
  Future<PaginationResponse<TenantUserSummary>> listUsers(UserQuery query) async {
    final response = await _remote.listUsers(query);
    return PaginationResponse<TenantUserSummary>(
      items: response.items.map((m) => m.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<UserDashboard> getDashboard() => _remote.getUserDashboard();

  @override
  Future<TenantUserDetail> getUser(String id) async {
    final model = await _remote.getUser(id);
    return model.toEntity();
  }

  @override
  Future<TenantUserDetail> createUser(UserFormPayload payload) async {
    final model = await _remote.createUser(payload.toJson());
    return model.toEntity();
  }

  @override
  Future<TenantUserDetail> updateUser(String id, UserFormPayload payload) async {
    final model = await _remote.updateUser(id, payload.toJson());
    return model.toEntity();
  }

  @override
  Future<void> deleteUser(String id) => _remote.deleteUser(id);

  @override
  Future<PaginationResponse<UserAuditEntry>> listUserAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listUserAudit(id, page: page, pageSize: pageSize);
    return PaginationResponse<UserAuditEntry>(
      items: response.items.map(_mapAudit).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<PaginationResponse<UserEventEntry>> listUserEvents(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listUserEvents(id, page: page, pageSize: pageSize);
    return PaginationResponse<UserEventEntry>(
      items: response.items.map(_mapEvent).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<UserEffectivePermissions> getUserEffectivePermissions(String id) =>
      _remote.getUserEffectivePermissions(id);

  @override
  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions() =>
      _remote.getCurrentUserEffectivePermissions();

  @override
  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  ) =>
      _remote.updateUserPermissions(userId, permissions);

  UserAuditEntry _mapAudit(Map<String, dynamic> json) => UserAuditEntry(
        id: json['id']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        entity: json['entity']?.toString() ?? '',
        entityId: json['entityId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  UserEventEntry _mapEvent(Map<String, dynamic> json) => UserEventEntry(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        entity: json['entity']?.toString() ?? '',
        entityId: json['entityId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class RoleRepositoryImpl implements RoleRepository {
  RoleRepositoryImpl(this._remote);

  final UserRemoteDataSource _remote;

  @override
  Future<List<RoleProfile>> listRoles() => _remote.listRoles();

  @override
  Future<RoleDetail> getRoleDetail(String role) => _remote.getRoleDetail(role);
}

class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl(this._remote);

  final UserRemoteDataSource _remote;

  @override
  Future<List<PermissionMatrixRow>> getMatrix({String? role}) =>
      _remote.getPermissionMatrix(role: role);

  @override
  Future<PermissionDashboard> getPermissionsDashboard() =>
      _remote.getPermissionDashboard();

  @override
  Future<void> updateRolePermissions(
    String role,
    List<RolePermissionGrant> grants,
  ) =>
      _remote.updateRolePermissions(role, grants);

  @override
  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  ) =>
      _remote.updateUserPermissions(userId, permissions);

  @override
  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions() =>
      _remote.getCurrentUserEffectivePermissions();
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});
