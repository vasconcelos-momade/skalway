import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/domain/entities/auth_session.dart';
import '../../core/errors/api_failure.dart';
import '../../modules/auth/data/repositories/auth_repository_impl.dart';

/// Estado global de autenticação e contexto tenant/branch.
class AuthSessionState {
  const AuthSessionState({
    this.isBootstrapping = false,
    this.isLoading = false,
    this.session,
    this.errorMessage,
  });

  final bool isBootstrapping;
  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => session != null;
  bool get hasTenantContext => session?.hasTenantContext ?? false;
  bool get isPlatformSession => session?.isPlatformSession ?? false;
  bool get isSuperAdmin => session?.isSuperAdmin ?? false;
  bool get isTenantRole => session?.isTenantRole ?? false;

  AuthSessionState copyWith({
    bool? isBootstrapping,
    bool? isLoading,
    AuthSession? session,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthSessionState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoading: isLoading ?? this.isLoading,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const bootstrapping = AuthSessionState(isBootstrapping: true);
  static const initial = AuthSessionState();
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    Future.microtask(_restoreSession);
    return AuthSessionState.bootstrapping;
  }

  Future<void> _restoreSession() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.restoreSession();
      if (session != null) {
        state = AuthSessionState(session: session);
      } else {
        state = AuthSessionState.initial;
      }
    } catch (_) {
      state = AuthSessionState.initial;
    }
  }

  /// Login único em `/login`. Devolve path de redirect ou null em falha.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(email: email.trim(), password: password);
      var session = result.session;

      if (session.isSuperAdmin) {
        session = session.copyWith(clearTenant: true, clearPermissions: true);
        await repo.saveSession(session);
        state = AuthSessionState(session: session);
        return result.redirectTo;
      }

      if (session.hasTenantContext) {
        session = session.copyWith(permissions: result.permissions);
        await repo.saveSession(session);
        state = AuthSessionState(session: session);
        return result.redirectTo;
      }

      state = AuthSessionState(session: session);
      return result.redirectTo;
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> selectTenantBranch({
    required String tenantId,
    required String branchId,
  }) async {
    final current = state.session;
    if (current == null) return;

    final updated = current.copyWith(
      tenantId: tenantId,
      branchId: branchId,
      clearPermissions: true,
    );
    await ref.read(authRepositoryProvider).persistTenantContext(
          tenantId: tenantId,
          branchId: branchId,
        );
    state = AuthSessionState(session: updated);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = AuthSessionState.initial;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(AuthSessionNotifier.new);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authSessionProvider).isAuthenticated,
);
