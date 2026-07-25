import '../entities/auth_session.dart';
import '../entities/login_result.dart';

abstract class AuthRepository {
  Future<LoginResult> login({required String email, required String password});

  Future<AuthSession?> restoreSession();

  Future<void> persistTenantContext({
    required String tenantId,
    required String branchId,
  });

  Future<void> saveSession(AuthSession session);

  Future<void> signOut();

  Future<void> requestPasswordReset({required String email});
}
