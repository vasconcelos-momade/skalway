import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/pdv_service_repository_impl.dart';
import '../../domain/entities/pdv_service.dart';

class PdvServiceListState {
  const PdvServiceListState({
    this.items = const <PdvService>[],
    this.query = '',
    this.page = 1,
    this.pageSize = 10,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<PdvService> items;
  final String query;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  PdvServiceListState copyWith({
    List<PdvService>? items,
    String? query,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PdvServiceListState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PdvServiceListController extends Notifier<PdvServiceListState> {
  final Map<String, PaginationResponse<PdvService>> _cache =
      <String, PaginationResponse<PdvService>>{};
  Timer? _debounce;
  int _requestId = 0;

  @override
  PdvServiceListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final previousSession = previous?.session;
      final nextSession = next.session;
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;

      if (!isReady) {
        _cache.clear();
        state = const PdvServiceListState();
        return;
      }

      final tenantChanged =
          previousSession?.tenantId != nextSession?.tenantId ||
          previousSession?.branchId != nextSession?.branchId;

      if (isReady && (!wasReady || tenantChanged)) {
        _cache.clear();
        unawaited(fetchCurrentPage(force: true));
      }
    });

    if (authReady) {
      Future.microtask(fetchCurrentPage);
    }
    return const PdvServiceListState();
  }

  String _cacheKey() =>
      '${state.query.toLowerCase()}|${state.page}|${state.pageSize}';

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      query: normalized,
      page: 1,
      clearError: true,
    );

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchCurrentPage();
    });
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await fetchCurrentPage();
  }

  Future<void> setPageSize(int pageSize) async {
    if (pageSize < 1 || pageSize == state.pageSize) {
      return;
    }
    state = state.copyWith(
      pageSize: pageSize,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    await fetchCurrentPage();
  }

  Future<void> refreshCurrentQuery() async {
    await fetchCurrentPage(force: true);
  }

  Future<void> fetchCurrentPage({bool force = false}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      _cache.clear();
      state = const PdvServiceListState();
      return;
    }

    final requestId = ++_requestId;
    final cacheKey = _cacheKey();

    if (!force && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      state = state.copyWith(
        items: cached.items,
        page: cached.page,
        pageSize: cached.pageSize,
        hasMore: cached.hasMore,
        totalCount: cached.totalCount,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(pdvServiceRepositoryProvider);
      final response = await repository.searchServices(
        query: state.query,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      _cache[cacheKey] = response;
      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final pdvServiceListProvider =
    NotifierProvider<PdvServiceListController, PdvServiceListState>(
  PdvServiceListController.new,
);
