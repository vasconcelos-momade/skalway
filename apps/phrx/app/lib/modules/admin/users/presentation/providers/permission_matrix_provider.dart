import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';

enum PermissionMatrixViewState { loading, loaded, error, saving }

const permissionMatrixActions = [
  'VIEW',
  'CREATE',
  'UPDATE',
  'DELETE',
  'APPROVE',
  'EXPORT',
];

class PermissionMatrixState {
  const PermissionMatrixState({
    this.rows = const <PermissionMatrixRow>[],
    this.dashboard = const PermissionDashboard(),
    this.selectedRole,
    this.editableMatrix = const <String, Map<String, bool>>{},
    this.viewState = PermissionMatrixViewState.loading,
    this.errorMessage,
  });

  final List<PermissionMatrixRow> rows;
  final PermissionDashboard dashboard;
  final String? selectedRole;
  final Map<String, Map<String, bool>> editableMatrix;
  final PermissionMatrixViewState viewState;
  final String? errorMessage;

  bool get isBusy =>
      viewState == PermissionMatrixViewState.loading ||
      viewState == PermissionMatrixViewState.saving;

  bool get canEdit => selectedRole != null;

  bool get hasChanges {
    if (!canEdit) return false;
    for (final row in rows) {
      final current = editableMatrix[row.module] ?? const {};
      final original = row.toBoolActions(permissionMatrixActions);
      for (final action in permissionMatrixActions) {
        if ((current[action] ?? false) != (original[action] ?? false)) {
          return true;
        }
      }
    }
    return false;
  }

  PermissionMatrixState copyWith({
    List<PermissionMatrixRow>? rows,
    PermissionDashboard? dashboard,
    String? selectedRole,
    Map<String, Map<String, bool>>? editableMatrix,
    PermissionMatrixViewState? viewState,
    String? errorMessage,
    bool clearRole = false,
    bool clearError = false,
  }) {
    return PermissionMatrixState(
      rows: rows ?? this.rows,
      dashboard: dashboard ?? this.dashboard,
      selectedRole: clearRole ? null : (selectedRole ?? this.selectedRole),
      editableMatrix: editableMatrix ?? this.editableMatrix,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PermissionMatrixController extends Notifier<PermissionMatrixState> {
  @override
  PermissionMatrixState build() {
    ref.listen<SessionAccessState>(sessionAccessProvider, (previous, next) {
      final wasAllowed = previous?.canAccessAdministration ?? false;
      if (next.canAccessAdministration && !wasAllowed) {
        Future.microtask(load);
      }
    });

    final canAccessAdministration = ref.watch(
      sessionAccessProvider.select((access) => access.canAccessAdministration),
    );
    if (canAccessAdministration) {
      Future.microtask(load);
    }

    return const PermissionMatrixState();
  }

  Map<String, Map<String, bool>> _matrixFromRows(List<PermissionMatrixRow> rows) {
    return {
      for (final row in rows)
        row.module: row.toBoolActions(permissionMatrixActions),
    };
  }

  Future<void> load({String? role}) async {
    if (!ref.read(sessionAccessProvider).canAccessAdministration) {
      return;
    }

    state = state.copyWith(
      viewState: PermissionMatrixViewState.loading,
      selectedRole: role,
      clearError: true,
    );
    try {
      final repo = ref.read(permissionRepositoryProvider);
      final results = await Future.wait([
        repo.getMatrix(role: role),
        repo.getPermissionsDashboard(),
      ]);
      final rows = results[0] as List<PermissionMatrixRow>;
      state = state.copyWith(
        rows: rows,
        dashboard: results[1] as PermissionDashboard,
        editableMatrix: role != null ? _matrixFromRows(rows) : const {},
        viewState: PermissionMatrixViewState.loaded,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        viewState: PermissionMatrixViewState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: PermissionMatrixViewState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setRoleFilter(String? role) => load(role: role);

  void togglePermission(String module, String action) {
    if (!state.canEdit || state.isBusy) return;
    final current = Map<String, Map<String, bool>>.from(state.editableMatrix);
    final moduleMap = Map<String, bool>.from(current[module] ?? {});
    moduleMap[action] = !(moduleMap[action] ?? false);
    current[module] = moduleMap;
    state = state.copyWith(editableMatrix: current);
  }

  void discardChanges() {
    if (!state.canEdit) return;
    state = state.copyWith(
      editableMatrix: _matrixFromRows(state.rows),
    );
  }

  Future<void> saveRolePermissions() async {
    if (!ref.read(sessionAccessProvider).canAccessAdministration) {
      return;
    }

    final role = state.selectedRole;
    if (role == null || !state.hasChanges) return;

    state = state.copyWith(
      viewState: PermissionMatrixViewState.saving,
      clearError: true,
    );

    try {
      final grants = <RolePermissionGrant>[];
      for (final row in state.rows) {
        final moduleMap = state.editableMatrix[row.module] ?? {};
        final original = row.toBoolActions(permissionMatrixActions);
        for (final action in permissionMatrixActions) {
          final next = moduleMap[action] ?? false;
          final before = original[action] ?? false;
          if (next != before) {
            grants.add(RolePermissionGrant(
              module: row.module,
              action: action,
              enabled: next,
            ));
          }
        }
      }

      if (grants.isEmpty) {
        state = state.copyWith(viewState: PermissionMatrixViewState.loaded);
        return;
      }

      await ref.read(permissionRepositoryProvider).updateRolePermissions(
            role,
            grants,
          );
      await load(role: role);
    } on ApiFailure catch (e) {
      state = state.copyWith(
        viewState: PermissionMatrixViewState.loaded,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        viewState: PermissionMatrixViewState.loaded,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final permissionMatrixProvider =
    NotifierProvider.autoDispose<PermissionMatrixController, PermissionMatrixState>(
  PermissionMatrixController.new,
);
