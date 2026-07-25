import '../entities/auth_session.dart';
import '../../../admin/users/domain/entities/user_entities.dart';

class LoginResult {
  const LoginResult({
    required this.session,
    required this.redirectTo,
    this.permissions,
  });

  final AuthSession session;
  final String redirectTo;
  final UserEffectivePermissions? permissions;
}
