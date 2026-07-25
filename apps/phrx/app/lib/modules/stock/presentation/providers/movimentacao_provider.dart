import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../core/errors/api_failure.dart';
import '../../data/repositories/movimentacao_repository_impl.dart';
import '../../domain/entities/movimentacao.dart';

enum MovimentacaoViewState { loading, loaded, empty, error, updating }

class MovimentacaoListState {
  const MovimentacaoListState({
    this.items = const <Movimentacao>[],
    this.query = const MovimentacaoQuery(),
    this.overview = MovimentacaoOverview.empty,
    this.filters = MovimentacaoFilters.empty,
    this.viewState = MovimentacaoViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.isInitialized = false,
    this.lastSyncedAt,
  });

  final List<Movimentacao> items;
  final MovimentacaoQuery query;
  final MovimentacaoOverview overview;
  final MovimentacaoFilters filters;
  final MovimentacaoViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final bool isInitialized;
  final DateTime? lastSyncedAt;

  bool get isBusy =>
      viewState == MovimentacaoViewState.loading ||
      viewState == MovimentacaoViewState.updating;

  MovimentacaoListState copyWith({
    List<Movimentacao>? items,
    MovimentacaoQuery? query,
    MovimentacaoOverview? overview,
    MovimentacaoFilters? filters,
    MovimentacaoViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    bool? isInitialized,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return MovimentacaoListState(
      items: items ?? this.items,
      query: query ?? this.query,
      overview: overview ?? this.overview,
      filters: filters ?? this.filters,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      isInitialized: isInitialized ?? this.isInitialized,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class MovimentacaoListController extends Notifier<MovimentacaoListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MovimentacaoListState build() {
    ref.onDispose(() => _debounce?.cancel());

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final wasReady =
          previous != null &&
          !previous.isBootstrapping &&
          previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;
      if (isReady && !wasReady) {
        unawaited(fetch());
      }
    });

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    if (authReady) {
      Future.microtask(fetch);
    }

    return const MovimentacaoListState();
  }

  void onSearchChanged(String value) {
    final nextQuery = state.query.copyWith(search: value.trim(), page: 1);
    _setQuery(nextQuery, debounce: true);
  }

  Future<void> setTipoFilter(String? tipo) async {
    await fetch(
      query: state.query.copyWith(page: 1, tipo: tipo, clearTipo: tipo == null),
    );
  }

  Future<void> setOrigemFilter(String? origem) async {
    await fetch(
      query: state.query.copyWith(
        page: 1,
        origem: origem,
        clearOrigem: origem == null,
      ),
    );
  }

  Future<void> setQuickFilter(MovimentacaoQuickFilter filter) async {
    final now = DateTime.now();
    DateTime? dataInicio;
    DateTime? dataFim;

    switch (filter) {
      case MovimentacaoQuickFilter.today:
        dataInicio = DateTime(now.year, now.month, now.day);
        dataFim = dataInicio;
        break;
      case MovimentacaoQuickFilter.week:
        final weekday = now.weekday;
        dataInicio = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        dataFim = DateTime(now.year, now.month, now.day);
        break;
      case MovimentacaoQuickFilter.month:
        dataInicio = DateTime(now.year, now.month, 1);
        dataFim = DateTime(now.year, now.month + 1, 0);
        break;
      case MovimentacaoQuickFilter.none:
        break;
    }

    await fetch(
      query: state.query.copyWith(
        page: 1,
        quickFilter: filter,
        dataInicio: dataInicio,
        dataFim: dataFim,
        clearDateRange: filter == MovimentacaoQuickFilter.none,
      ),
    );
  }

  Future<void> setDateRange(DateTimeRange? range) async {
    await fetch(
      query: state.query.copyWith(
        page: 1,
        quickFilter: MovimentacaoQuickFilter.none,
        dataInicio: range?.start == null
            ? null
            : DateTime(range!.start.year, range.start.month, range.start.day),
        dataFim: range?.end == null
            ? null
            : DateTime(range!.end.year, range.end.month, range.end.day),
        clearDateRange: range == null,
      ),
    );
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.query.page) {
      return;
    }
    await fetch(query: state.query.copyWith(page: page));
  }

  Future<void> setPageSize(int pageSize) async {
    final normalized = pageSize.clamp(10, 100);
    if (normalized == state.query.pageSize) {
      return;
    }
    await fetch(query: state.query.copyWith(page: 1, pageSize: normalized));
  }

  Future<void> refresh() async {
    await fetch();
  }

  Future<void> clearFilters() async {
    await fetch(query: const MovimentacaoQuery());
  }

  Future<void> fetch({MovimentacaoQuery? query}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      return;
    }

    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized
          ? MovimentacaoViewState.updating
          : MovimentacaoViewState.loading,
      clearError: true,
    );

    try {
      final response = await ref
          .read(movimentacaoRepositoryProvider)
          .listarMovimentacoes(nextQuery);

      if (requestId != _requestId) {
        return;
      }

      final newViewState = response.items.isEmpty
          ? MovimentacaoViewState.empty
          : MovimentacaoViewState.loaded;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(
          page: response.page,
          pageSize: response.pageSize,
        ),
        overview: response.overview,
        filters: response.filters,
        hasMore: response.hasMore,
        viewState: newViewState,
        isInitialized: true,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? MovimentacaoViewState.error
            : MovimentacaoViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? MovimentacaoViewState.error
            : MovimentacaoViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  void _setQuery(MovimentacaoQuery query, {bool debounce = false}) {
    state = state.copyWith(query: query, clearError: true);

    if (!debounce) {
      unawaited(fetch(query: query));
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(fetch(query: query));
    });
  }
}

final movimentacaoListProvider =
    NotifierProvider.autoDispose<
      MovimentacaoListController,
      MovimentacaoListState
    >(MovimentacaoListController.new);
