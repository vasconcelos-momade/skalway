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
  });

  final UserEffectivePermissions? permissions;
  final SessionAccessViewState viewState;
  final String? errorMessage;

  bool get isLoading => viewState == SessionAccessViewState.loading;
  bool get isResolved =>
      viewState == SessionAccessViewState.loaded ||
      viewState == SessionAccessViewState.error;

  bool can(String module, String action) {
    final entries = permissions?.permissions;
    if (entries == null) return false;
    return entries.any(
      (entry) =>
          entry.allowed &&
          entry.module.toUpperCase() == module.toUpperCase() &&
          entry.action.toUpperCase() == action.toUpperCase(),
    );
  }

  bool get canAccessAdministration => can('UTILIZADORES', 'VIEW');

  SessionAccessState copyWith({
    UserEffectivePermissions? permissions,
    SessionAccessViewState? viewState,
    String? errorMessage,
    bool clearPermissions = false,
    bool clearError = false,
  }) {
    return SessionAccessState(
      permissions: clearPermissions ? null : (permissions ?? this.permissions),
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
    if (!ref.read(authSessionProvider).hasTenantContext) {
      state = const SessionAccessState();
      return;
    }

    final requestId = ++_requestId;
    state = state.copyWith(
      viewState: SessionAccessViewState.loading,
      clearError: true,
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
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: SessionAccessViewState.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final sessionAccessProvider =
    NotifierProvider<SessionAccessNotifier, SessionAccessState>(
  SessionAccessNotifier.new,
);
