import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/tenant_access.dart';
import '../models/login_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> saveTenantContext({required String tenantId, required String branchId});
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secure);

  final SecureStorageService _secure;

  @override
  Future<void> saveSession(AuthSession session) async {
    await _secure.writeAccessToken(session.accessToken);
    await _secure.writeRefreshToken(session.refreshToken);
    await _secure.writeUserJson(jsonEncode(_userToMap(session.user)));
    await _secure.writeTenantsJson(jsonEncode(_tenantsToJson(session.tenants)));
    if (session.tenantId != null && session.branchId != null) {
      await saveTenantContext(
        tenantId: session.tenantId!,
        branchId: session.branchId!,
      );
    } else if (session.isSuperAdmin) {
      await _secure.writeTenantId(null);
      await _secure.writeBranchId(null);
    }
  }

  @override
  Future<AuthSession?> readSession() async {
    final token = await _secure.readAccessToken();
    final refreshToken = await _secure.readRefreshToken();
    final userJson = await _secure.readUserJson();
    final tenantsJson = await _secure.readTenantsJson();
    if (token == null || userJson == null || tenantsJson == null) {
      return null;
    }

    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final tenantsList = jsonDecode(tenantsJson) as List<dynamic>;
    final tenantId = await _secure.readTenantId();
    final branchId = await _secure.readBranchId();

    return AuthSession(
      accessToken: token,
      refreshToken: refreshToken,
      user: AuthUserModel.fromJson(userMap),
      tenants: tenantsList
          .whereType<Map<String, dynamic>>()
          .map(TenantAccessModel.fromJson)
          .toList(),
      tenantId: tenantId,
      branchId: branchId,
    );
  }

  @override
  Future<void> saveTenantContext({
    required String tenantId,
    required String branchId,
  }) async {
    await _secure.writeTenantId(tenantId);
    await _secure.writeBranchId(branchId);
  }

  @override
  Future<void> clearSession() => _secure.clearAuth();

  Map<String, dynamic> _userToMap(AuthUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role,
      };

  List<Map<String, dynamic>> _tenantsToJson(List<TenantAccess> tenants) {
    return tenants
        .map(
          (t) => {
            'id': t.id,
            'companyName': t.companyName,
            'name': t.name,
            'branches': t.branches
                .map(
                  (b) => {
                    'id': b.id,
                    'code': b.code,
                    'name': b.name,
                  },
                )
                .toList(),
          },
        )
        .toList();
  }
}

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});
