import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/entities/audit_entities.dart';

enum AuditViewState { loading, loaded, empty, error, updating }

class AuditDashboardState {
  const AuditDashboardState({
    this.dashboard = const AuditDashboard(),
    this.viewState = AuditViewState.loading,
    this.errorMessage,
  });

  final AuditDashboard dashboard;
  final AuditViewState viewState;
  final String? errorMessage;

  bool get isBusy => viewState == AuditViewState.loading;

  AuditDashboardState copyWith({
    AuditDashboard? dashboard,
    AuditViewState? viewState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuditDashboardState(
      dashboard: dashboard ?? this.dashboard,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuditDashboardController extends Notifier<AuditDashboardState> {
  @override
  AuditDashboardState build() {
    Future.microtask(load);
    return const AuditDashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(viewState: AuditViewState.loading, clearError: true);
    try {
      final dashboard = await ref.read(auditRepositoryProvider).getDashboard();
      state = state.copyWith(
        dashboard: dashboard,
        viewState: AuditViewState.loaded,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(viewState: AuditViewState.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(viewState: AuditViewState.error, errorMessage: e.toString());
    }
  }
}

final auditDashboardProvider =
    NotifierProvider.autoDispose<AuditDashboardController, AuditDashboardState>(
  AuditDashboardController.new,
);

class AuditListState<T> {
  const AuditListState({
    this.items = const [],
    this.query = const AuditQuery(),
    this.viewState = AuditViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.totalCount,
    this.isInitialized = false,
  });

  final List<T> items;
  final AuditQuery query;
  final AuditViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final int? totalCount;
  final bool isInitialized;

  bool get isBusy =>
      viewState == AuditViewState.loading || viewState == AuditViewState.updating;

  AuditListState<T> copyWith({
    List<T>? items,
    AuditQuery? query,
    AuditViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    int? totalCount,
    bool? isInitialized,
    bool clearError = false,
    bool clearTotalCount = false,
  }) {
    return AuditListState<T>(
      items: items ?? this.items,
      query: query ?? this.query,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuditLogsController extends Notifier<AuditListState<AuditLogEntry>> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  AuditListState<AuditLogEntry> build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(fetch);
    return const AuditListState();
  }

  void onSearchChanged(String value) {
    final next = state.query.copyWith(search: value.trim(), page: 1);
    _debounce?.cancel();
    state = state.copyWith(query: next, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => fetch(query: next));
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

  Future<void> clearFilters() => fetch(query: const AuditQuery());

  Future<void> fetch({AuditQuery? query, bool force = false}) async {
    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized ? AuditViewState.updating : AuditViewState.loading,
      clearError: true,
    );

    try {
      final response = await ref.read(auditRepositoryProvider).listLogs(nextQuery);
      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(page: response.page, pageSize: response.pageSize),
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        viewState: response.items.isEmpty ? AuditViewState.empty : AuditViewState.loaded,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? AuditViewState.error : AuditViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? AuditViewState.error : AuditViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final auditLogsProvider =
    NotifierProvider.autoDispose<AuditLogsController, AuditListState<AuditLogEntry>>(
  AuditLogsController.new,
);

class AuditEventsController extends Notifier<AuditListState<AuditEventSummary>> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  AuditListState<AuditEventSummary> build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(fetch);
    return const AuditListState();
  }

  void onSearchChanged(String value) {
    final next = state.query.copyWith(search: value.trim(), page: 1);
    _debounce?.cancel();
    state = state.copyWith(query: next, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => fetch(query: next));
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

  Future<void> clearFilters() => fetch(query: const AuditQuery());

  Future<void> fetch({AuditQuery? query, bool force = false}) async {
    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized ? AuditViewState.updating : AuditViewState.loading,
      clearError: true,
    );

    try {
      final response = await ref.read(auditRepositoryProvider).listEvents(nextQuery);
      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(page: response.page, pageSize: response.pageSize),
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        viewState: response.items.isEmpty ? AuditViewState.empty : AuditViewState.loaded,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? AuditViewState.error : AuditViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty ? AuditViewState.error : AuditViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final auditEventsProvider =
    NotifierProvider.autoDispose<AuditEventsController, AuditListState<AuditEventSummary>>(
  AuditEventsController.new,
);
