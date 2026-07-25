import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';

class ExpiryViewState {
  const ExpiryViewState({
    this.dashboard,
    this.items = const <Map<String, dynamic>>[],
    this.bucket = 'todos',
    this.query = '',
    this.sortBy = 'dataValidade',
    this.sortDescending = false,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.totalCount,
    this.lastUpdated,
  });

  final Map<String, dynamic>? dashboard;
  final List<Map<String, dynamic>> items;
  final String bucket;
  final String query;
  final String sortBy;
  final bool sortDescending;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final DateTime? lastUpdated;

  ExpiryViewState copyWith({
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? items,
    String? bucket,
    String? query,
    String? sortBy,
    bool? sortDescending,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    DateTime? lastUpdated,
  }) {
    return ExpiryViewState(
      dashboard: dashboard ?? this.dashboard,
      items: items ?? this.items,
      bucket: bucket ?? this.bucket,
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ExpiryViewController extends AsyncNotifier<ExpiryViewState> {
  static ExpiryViewState? _cache;

  @override
  Future<ExpiryViewState> build() async {
    ref.keepAlive();
    return _cache ?? _load(const ExpiryViewState(), force: true);
  }

  Future<void> refresh({bool force = false}) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(current, force: force));
  }

  Future<void> setBucket(String bucket) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(bucket: bucket, page: 1), force: true),
    );
  }

  Future<void> setSearch(String value) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(query: value.trim(), page: 1), force: true),
    );
  }

  Future<void> setSort(String sortBy) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    final descending = current.sortBy == sortBy
        ? !current.sortDescending
        : false;
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(sortBy: sortBy, sortDescending: descending),
        force: true,
      ),
    );
  }

  Future<void> goToPage(int page) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(page: page), force: true),
    );
  }

  Future<void> setPageSize(int pageSize) async {
    final current = state.valueOrNull ?? _cache ?? const ExpiryViewState();
    if (current.pageSize == pageSize) return;
    state = await AsyncValue.guard(
      () => _load(current.copyWith(pageSize: pageSize, page: 1), force: true),
    );
  }

  Future<ExpiryViewState> _load(
    ExpiryViewState current, {
    required bool force,
  }) async {
    final now = DateTime.now();
    if (!force &&
        current.lastUpdated != null &&
        now.difference(current.lastUpdated!) < const Duration(seconds: 30)) {
      return current;
    }

    final ds = ref.read(inventoryRemoteDataSourceProvider);
    final dashboard = await ds.validadesDashboard();
    final response = await ds.searchValidades(
      query: current.query.isEmpty ? null : current.query,
      bucket: current.bucket,
      page: current.page,
      pageSize: current.pageSize,
    );

    final items = [...response.items];
    items.sort((a, b) {
      final left = _comparableValue(a[current.sortBy]);
      final right = _comparableValue(b[current.sortBy]);
      final result = left.compareTo(right);
      return current.sortDescending ? -result : result;
    });

    final next = current.copyWith(
      dashboard: dashboard,
      items: items,
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
      lastUpdated: now,
    );
    _cache = next;
    return next;
  }

  Comparable<Object> _comparableValue(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final parsedDate = DateTime.tryParse(value);
      if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
      final parsedNum = num.tryParse(value);
      if (parsedNum != null) return parsedNum;
      return value.toLowerCase();
    }
    return value?.toString().toLowerCase() ?? '';
  }
}

final expiryViewProvider =
    AsyncNotifierProvider<ExpiryViewController, ExpiryViewState>(
      ExpiryViewController.new,
    );
