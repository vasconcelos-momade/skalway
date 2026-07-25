import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';

class LotsViewState {
  const LotsViewState({
    this.dashboard,
    this.items = const <Map<String, dynamic>>[],
    this.query = '',
    this.estadoSanitario,
    this.disponibilidade,
    this.expirado,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.totalCount,
    this.lastUpdated,
    this.actionLoteId,
  });

  final Map<String, dynamic>? dashboard;
  final List<Map<String, dynamic>> items;
  final String query;
  final String? estadoSanitario;
  final String? disponibilidade;
  final bool? expirado;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final DateTime? lastUpdated;
  final String? actionLoteId;

  LotsViewState copyWith({
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? items,
    String? query,
    String? estadoSanitario,
    bool clearEstadoSanitario = false,
    String? disponibilidade,
    bool clearDisponibilidade = false,
    bool? expirado,
    bool clearExpirado = false,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    DateTime? lastUpdated,
    String? actionLoteId,
    bool clearActionLoteId = false,
  }) {
    return LotsViewState(
      dashboard: dashboard ?? this.dashboard,
      items: items ?? this.items,
      query: query ?? this.query,
      estadoSanitario: clearEstadoSanitario
          ? null
          : (estadoSanitario ?? this.estadoSanitario),
      disponibilidade: clearDisponibilidade
          ? null
          : (disponibilidade ?? this.disponibilidade),
      expirado: clearExpirado ? null : (expirado ?? this.expirado),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      actionLoteId: clearActionLoteId
          ? null
          : (actionLoteId ?? this.actionLoteId),
    );
  }
}

class LotsViewController extends AsyncNotifier<LotsViewState> {
  static LotsViewState? _cache;

  @override
  Future<LotsViewState> build() async {
    ref.keepAlive();
    return _cache ?? _load(const LotsViewState(), force: true);
  }

  Future<void> refresh({bool force = false}) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(current, force: force));
  }

  Future<void> setSearch(String value) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(query: value.trim(), page: 1), force: true),
    );
  }

  Future<void> setEstadoSanitario(String? value) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(
          estadoSanitario: value,
          clearEstadoSanitario: value == null,
          page: 1,
        ),
        force: true,
      ),
    );
  }

  Future<void> setDisponibilidade(String? value) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(
          disponibilidade: value,
          clearDisponibilidade: value == null,
          page: 1,
        ),
        force: true,
      ),
    );
  }

  Future<void> setExpirado(bool? value) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = await AsyncValue.guard(
      () => _load(
        current.copyWith(
          expirado: value,
          clearExpirado: value == null,
          page: 1,
        ),
        force: true,
      ),
    );
  }

  Future<void> goToPage(int page) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(page: page), force: true),
    );
  }

  Future<void> setPageSize(int pageSize) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    if (current.pageSize == pageSize) return;
    state = await AsyncValue.guard(
      () => _load(current.copyWith(pageSize: pageSize, page: 1), force: true),
    );
  }

  Future<void> moveToQuarentena({
    required String loteId,
    required num quantidade,
    required String motivo,
    String? documentoReferencia,
  }) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = AsyncData(current.copyWith(actionLoteId: loteId));
    try {
      final ds = ref.read(inventoryRemoteDataSourceProvider);
      await ds.moveLoteToQuarentena(
        loteId,
        quantidade: quantidade,
        motivo: motivo,
        documentoReferencia: documentoReferencia,
      );
      await refresh(force: true);
    } finally {
      final latest = state.valueOrNull ?? current;
      if (latest.actionLoteId == loteId) {
        state = AsyncData(latest.copyWith(clearActionLoteId: true));
      }
    }
  }

  Future<void> revertQuarentena({
    required String loteId,
    required String motivo,
    num? quantidade,
    String? documentoReferencia,
  }) async {
    final current = state.valueOrNull ?? _cache ?? const LotsViewState();
    state = AsyncData(current.copyWith(actionLoteId: loteId));
    try {
      final ds = ref.read(inventoryRemoteDataSourceProvider);
      await ds.revertLoteQuarentena(
        loteId,
        quantidade: quantidade,
        motivo: motivo,
        documentoReferencia: documentoReferencia,
      );
      await refresh(force: true);
    } finally {
      final latest = state.valueOrNull ?? current;
      if (latest.actionLoteId == loteId) {
        state = AsyncData(latest.copyWith(clearActionLoteId: true));
      }
    }
  }

  Future<LotsViewState> _load(
    LotsViewState current, {
    required bool force,
  }) async {
    final now = DateTime.now();
    if (!force &&
        current.lastUpdated != null &&
        now.difference(current.lastUpdated!) < const Duration(seconds: 30)) {
      return current;
    }

    final ds = ref.read(inventoryRemoteDataSourceProvider);
    final results = await Future.wait([
      ds.lotesDashboard(),
      ds.searchLotes(
        query: current.query.isEmpty ? null : current.query,
        estadoSanitario: current.estadoSanitario,
        disponibilidade: current.disponibilidade,
        expirado: current.expirado,
        page: current.page,
        pageSize: current.pageSize,
      ),
    ]);

    final next = current.copyWith(
      dashboard: results[0] as Map<String, dynamic>,
      items: (results[1] as dynamic).items as List<Map<String, dynamic>>,
      page: (results[1] as dynamic).page as int,
      pageSize: (results[1] as dynamic).pageSize as int,
      hasMore: (results[1] as dynamic).hasMore as bool,
      totalCount: (results[1] as dynamic).totalCount as int?,
      lastUpdated: now,
    );
    _cache = next;
    return next;
  }
}

final lotsViewProvider =
    AsyncNotifierProvider<LotsViewController, LotsViewState>(
      LotsViewController.new,
    );
