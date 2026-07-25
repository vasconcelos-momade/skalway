import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';

enum UserViewState { loading, loaded, empty, error, updating }

class UserListState {
  const UserListState({
    this.items = const <TenantUserSummary>[],
    this.query = const UserQuery(),
    this.dashboard = const UserDashboard(),
    this.viewState = UserViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.totalCount,
    this.isInitialized = false,
  });

  final List<TenantUserSummary> items;
  final UserQuery query;
  final UserDashboard dashboard;
  final UserViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final int? totalCount;
  final bool isInitialized;

  bool get isBusy =>
      viewState == UserViewState.loading || viewState == UserViewState.updating;

  UserListState copyWith({
    List<TenantUserSummary>? items,
    UserQuery? query,
    UserDashboard? dashboard,
    UserViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    int? totalCount,
    bool? isInitialized,
    bool clearError = false,
    bool clearTotalCount = false,
  }) {
    return UserListState(
      items: items ?? this.items,
      query: query ?? this.query,
      dashboard: dashboard ?? this.dashboard,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class UserListController extends Notifier<UserListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  UserListState build() {
    ref.onDispose(() => _debounce?.cancel());

    ref.listen<SessionAccessState>(sessionAccessProvider, (previous, next) {
      final wasAllowed = previous?.canAccessAdministration ?? false;
      if (next.canAccessAdministration && !wasAllowed) {
        unawaited(fetch());
      }
    });

    final canAccessAdministration = ref.watch(
      sessionAccessProvider.select((access) => access.canAccessAdministration),
    );
    if (canAccessAdministration) {
      Future.microtask(fetch);
    }

    return const UserListState();
  }

  void onSearchChanged(String value) {
    final next = state.query.copyWith(search: value.trim(), page: 1);
    _debounce?.cancel();
    state = state.copyWith(query: next, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => fetch(query: next));
  }

  Future<void> setRoleFilter(String? role) async {
    await fetch(
      query: state.query.copyWith(page: 1, role: role, clearRole: role == null),
    );
  }

  Future<void> setActiveFilter(bool? active) async {
    await fetch(
      query: state.query.copyWith(
        page: 1,
        active: active,
        clearActive: active == null,
      ),
    );
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.query.page) return;
    await fetch(query: state.query.copyWith(page: page));
  }

  Future<void> setPageSize(int pageSize) async {
    final normalized = pageSize.clamp(5, 100);
    if (normalized == state.query.pageSize) return;
    await fetch(query: state.query.copyWith(page: 1, pageSize: normalized));
  }

  Future<void> refresh() => fetch(force: true);

  Future<void> clearFilters() => fetch(query: const UserQuery());

  Future<TenantUserDetail> createUser(UserFormPayload payload) async {
    final created = await ref.read(userRepositoryProvider).createUser(payload);
    await fetch(force: true);
    return created;
  }

  Future<TenantUserDetail> updateUser(String id, UserFormPayload payload) async {
    final updated =
        await ref.read(userRepositoryProvider).updateUser(id, payload);
    await fetch(force: true);
    return updated;
  }

  Future<void> deleteUser(String id) async {
    await ref.read(userRepositoryProvider).deleteUser(id);
    await fetch(force: true);
  }

  Future<void> fetch({UserQuery? query, bool force = false}) async {
    if (!ref.read(sessionAccessProvider).canAccessAdministration) {
      return;
    }

    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized ? UserViewState.updating : UserViewState.loading,
      clearError: true,
    );

    try {
      final repo = ref.read(userRepositoryProvider);
      final response = await repo.listUsers(nextQuery);
      UserDashboard dashboard = state.dashboard;
      if (!state.isInitialized || force) {
        dashboard = await repo.getDashboard();
      }

      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(page: response.page, pageSize: response.pageSize),
        dashboard: dashboard,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        viewState: response.items.isEmpty ? UserViewState.empty : UserViewState.loaded,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? UserViewState.error : UserViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? UserViewState.error : UserViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final userListProvider =
    NotifierProvider.autoDispose<UserListController, UserListState>(
  UserListController.new,
);
