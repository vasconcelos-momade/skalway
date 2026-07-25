import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _remote.login(email: email, password: password);

    final session = AuthSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: response.user,
      tenants: response.tenants,
      tenantId: response.tenantId,
      branchId: response.branchId,
      permissions: response.permissions,
    );
    await _local.saveSession(session);
    return LoginResult(
      session: session,
      redirectTo: response.redirectTo,
      permissions: response.permissions,
    );
  }

  @override
  Future<AuthSession?> restoreSession() => _local.readSession();

  @override
  Future<void> persistTenantContext({
    required String tenantId,
    required String branchId,
  }) async {
    await _local.saveTenantContext(tenantId: tenantId, branchId: branchId);
    final current = await _local.readSession();
    if (current != null) {
      await _local.saveSession(
        current.copyWith(tenantId: tenantId, branchId: branchId),
      );
    }
  }

  @override
  Future<void> saveSession(AuthSession session) => _local.saveSession(session);

  @override
  Future<void> signOut() async {
    await _local.clearSession();
  }

  @override
  Future<void> requestPasswordReset({required String email}) {
    return _remote.requestPasswordReset(email: email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});
