import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';

enum RoleListViewState { loading, loaded, error }

class RoleListState {
  const RoleListState({
    this.roles = const <RoleProfile>[],
    this.selected,
    this.viewState = RoleListViewState.loading,
    this.errorMessage,
  });

  final List<RoleProfile> roles;
  final RoleDetail? selected;
  final RoleListViewState viewState;
  final String? errorMessage;

  bool get isBusy => viewState == RoleListViewState.loading;

  RoleListState copyWith({
    List<RoleProfile>? roles,
    RoleDetail? selected,
    RoleListViewState? viewState,
    String? errorMessage,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return RoleListState(
      roles: roles ?? this.roles,
      selected: clearSelected ? null : (selected ?? this.selected),
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RoleListController extends Notifier<RoleListState> {
  @override
  RoleListState build() {
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

    return const RoleListState();
  }

  Future<void> load() async {
    if (!ref.read(sessionAccessProvider).canAccessAdministration) {
      return;
    }

    state = state.copyWith(viewState: RoleListViewState.loading, clearError: true);
    try {
      final roles = await ref.read(roleRepositoryProvider).listRoles();
      state = state.copyWith(
        roles: roles,
        viewState: RoleListViewState.loaded,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(viewState: RoleListViewState.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(viewState: RoleListViewState.error, errorMessage: e.toString());
    }
  }

  Future<void> selectRole(String role) async {
    if (!ref.read(sessionAccessProvider).canAccessAdministration) {
      return;
    }

    try {
      final detail = await ref.read(roleRepositoryProvider).getRoleDetail(role);
      state = state.copyWith(selected: detail, clearError: true);
    } on ApiFailure catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void clearSelection() => state = state.copyWith(clearSelected: true);
}

final roleListProvider =
    NotifierProvider.autoDispose<RoleListController, RoleListState>(
  RoleListController.new,
);
