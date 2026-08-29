import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/admin/users/data/repositories/user_repository_impl.dart';
import '../../modules/admin/users/domain/entities/user_entities.dart';
import 'auth_session_notifier.dart';

enum SessionAccessViewState { idle, loading, loaded, error }

class SessionAccessState {
  const SessionAccessState({
    this.permissions,
    this.viewState = SessionAccessViewState.idle,
    this.errorMessage,
    this.superAdminFullAccess = false,
  });

  final UserEffectivePermissions? permissions;
  final SessionAccessViewState viewState;
  final String? errorMessage;
  final bool superAdminFullAccess;

  bool get isLoading => viewState == SessionAccessViewState.loading;
  bool get isResolved =>
      viewState == SessionAccessViewState.loaded ||
      viewState == SessionAccessViewState.error;

  bool can(String module, String action) {
    if (superAdminFullAccess) return true;
    final entries = permissions?.permissions;
    if (entries == null) return false;
    return entries.any(
      (entry) =>
          entry.allowed &&
          entry.module.toUpperCase() == module.toUpperCase() &&
          entry.action.toUpperCase() == action.toUpperCase(),
    );
  }

  bool get canAccessAdministration =>
      superAdminFullAccess || can('UTILIZADORES', 'VIEW');

  /// Espelha [canApprovePurchaseSuggestionQuantity] do backend (UX apenas).
  bool get canEditPurchaseApprovedQuantity {
    if (superAdminFullAccess) return true;
    final role = permissions?.role;
    return role == 'GERENTE' ||
        role == 'DIRETOR_TECNICO' ||
        role == 'ADMIN';
  }

  SessionAccessState copyWith({
    UserEffectivePermissions? permissions,
    SessionAccessViewState? viewState,
    String? errorMessage,
    bool? superAdminFullAccess,
    bool clearPermissions = false,
    bool clearError = false,
  }) {
    return SessionAccessState(
      permissions: clearPermissions ? null : (permissions ?? this.permissions),
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      superAdminFullAccess:
          superAdminFullAccess ?? this.superAdminFullAccess,
    );
  }
}

class SessionAccessNotifier extends Notifier<SessionAccessState> {
  int _requestId = 0;

  @override
  SessionAccessState build() {
    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;

      if (!isReady) {
        _requestId++;
        state = const SessionAccessState();
        return;
      }

      final cached = next.session?.permissions;
      if (cached != null) {
        _requestId++;
        state = SessionAccessState(
          permissions: cached,
          viewState: SessionAccessViewState.loaded,
          superAdminFullAccess: next.isSuperAdmin,
        );
        return;
      }

      if (next.isSuperAdmin) {
        _requestId++;
        state = const SessionAccessState(
          viewState: SessionAccessViewState.loaded,
          superAdminFullAccess: true,
        );
        return;
      }

      final sessionChanged =
          previous?.session?.tenantId != next.session?.tenantId ||
          previous?.session?.branchId != next.session?.branchId ||
          previous?.session?.accessToken != next.session?.accessToken;
      if (!wasReady || sessionChanged) {
        unawaited(refresh());
      }
    });

    final auth = ref.watch(authSessionProvider);
    if (!auth.isBootstrapping && auth.hasTenantContext) {
      if (auth.isSuperAdmin) {
        return const SessionAccessState(
          viewState: SessionAccessViewState.loaded,
          superAdminFullAccess: true,
        );
      }
      final cached = auth.session?.permissions;
      if (cached != null) {
        return SessionAccessState(
          permissions: cached,
          viewState: SessionAccessViewState.loaded,
        );
      }
      Future.microtask(refresh);
    }

    return const SessionAccessState();
  }

  Future<void> refresh() async {
    final auth = ref.read(authSessionProvider);
    if (!auth.hasTenantContext) {
      state = const SessionAccessState();
      return;
    }

    final requestId = ++_requestId;

    if (auth.isSuperAdmin) {
      state = const SessionAccessState(
        viewState: SessionAccessViewState.loaded,
        superAdminFullAccess: true,
      );
      return;
    }

    state = state.copyWith(
      viewState: SessionAccessViewState.loading,
      clearError: true,
      superAdminFullAccess: false,
    );

    try {
      final permissions = await ref
          .read(permissionRepositoryProvider)
          .getCurrentUserEffectivePermissions();
      if (requestId != _requestId) return;
      state = state.copyWith(
        permissions: permissions,
        viewState: SessionAccessViewState.loaded,
        clearError: true,
        superAdminFullAccess: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: SessionAccessViewState.error,
        errorMessage: e.toString(),
        superAdminFullAccess: false,
      );
    }
  }
}

final sessionAccessProvider =
    NotifierProvider<SessionAccessNotifier, SessionAccessState>(
  SessionAccessNotifier.new,
);
