import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';

class FefoViewState {
  const FefoViewState({
    this.dashboard,
    this.overview = const <Map<String, dynamic>>[],
    this.audit = const <Map<String, dynamic>>[],
    this.query = '',
    this.situacao,
    this.pageOverview = 1,
    this.pageAudit = 1,
    this.pageSize = 20,
    this.hasMoreOverview = false,
    this.hasMoreAudit = false,
    this.totalCountOverview,
    this.totalCountAudit,
    this.lastUpdated,
  });

  final Map<String, dynamic>? dashboard;
  final List<Map<String, dynamic>> overview;
  final List<Map<String, dynamic>> audit;
  final String query;
  final String? situacao;
  final int pageOverview;
  final int pageAudit;
  final int pageSize;
  final bool hasMoreOverview;
  final bool hasMoreAudit;
  final int? totalCountOverview;
  final int? totalCountAudit;
  final DateTime? lastUpdated;

  FefoViewState copyWith({
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? overview,
    List<Map<String, dynamic>>? audit,
    String? query,
    String? situacao,
    bool clearSituacao = false,
    int? pageOverview,
    int? pageAudit,
    int? pageSize,
    bool? hasMoreOverview,
    bool? hasMoreAudit,
    int? totalCountOverview,
    int? totalCountAudit,
    DateTime? lastUpdated,
  }) {
    return FefoViewState(
      dashboard: dashboard ?? this.dashboard,
      overview: overview ?? this.overview,
      audit: audit ?? this.audit,
      query: query ?? this.query,
      situacao: clearSituacao ? null : (situacao ?? this.situacao),
      pageOverview: pageOverview ?? this.pageOverview,
      pageAudit: pageAudit ?? this.pageAudit,
      pageSize: pageSize ?? this.pageSize,
      hasMoreOverview: hasMoreOverview ?? this.hasMoreOverview,
      hasMoreAudit: hasMoreAudit ?? this.hasMoreAudit,
      totalCountOverview: totalCountOverview ?? this.totalCountOverview,
      totalCountAudit: totalCountAudit ?? this.totalCountAudit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class FefoViewController extends AsyncNotifier<FefoViewState> {
  static FefoViewState? _cache;

  @override
  Future<FefoViewState> build() async {
    ref.keepAlive();
    return _cache ?? _load(const FefoViewState(), force: true);
  }

  Future<void> refresh({bool force = false}) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(current, force: force));
  }

  Future<void> setSearch(String value) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(
          query: value.trim(),
          pageOverview: 1,
          pageAudit: 1,
        ),
        force: true,
      ),
    );
  }

  Future<void> setSituacao(String? value) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(
          situacao: value,
          clearSituacao: value == null,
          pageAudit: 1,
        ),
        force: true,
      ),
    );
  }

  Future<void> goToPageOverview(int page) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(pageOverview: page), force: true),
    );
  }

  Future<void> goToPageAudit(int page) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(pageAudit: page), force: true),
    );
  }

  Future<void> setPageSize(int pageSize) async {
    final current = state.valueOrNull ?? _cache ?? const FefoViewState();
    if (current.pageSize == pageSize) return;
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(pageSize: pageSize, pageOverview: 1, pageAudit: 1),
        force: true,
      ),
    );
  }

  Future<FefoViewState> _load(FefoViewState current, {required bool force}) async {
    final now = DateTime.now();
    if (!force &&
        current.lastUpdated != null &&
        now.difference(current.lastUpdated!) < const Duration(seconds: 30)) {
      return current;
    }

    final ds = ref.read(inventoryRemoteDataSourceProvider);
    final dashboard = await ds.fefoDashboard();
    final overviewResponse = await ds.searchFefoOverview(
      query: current.query.isEmpty ? null : current.query,
      page: current.pageOverview,
      pageSize: current.pageSize,
    );
    PaginationResponse<Map<String, dynamic>> auditResponse;
    try {
      auditResponse = await ds.searchFefoAudit(
        query: current.query.isEmpty ? null : current.query,
        situacao: current.situacao,
        page: current.pageAudit,
        pageSize: current.pageSize,
      );
    } catch (_) {
      auditResponse = PaginationResponse<Map<String, dynamic>>(
        items: const [],
        page: current.pageAudit,
        pageSize: current.pageSize,
        hasMore: false,
      );
    }

    final next = current.copyWith(
      dashboard: dashboard,
      overview: overviewResponse.items,
      audit: auditResponse.items,
      pageOverview: overviewResponse.page,
      pageAudit: auditResponse.page,
      hasMoreOverview: overviewResponse.hasMore,
      hasMoreAudit: auditResponse.hasMore,
      totalCountOverview: overviewResponse.totalCount,
      totalCountAudit: auditResponse.totalCount,
      lastUpdated: now,
    );
    _cache = next;
    return next;
  }
}

final fefoViewProvider =
    AsyncNotifierProvider<FefoViewController, FefoViewState>(
  FefoViewController.new,
);
