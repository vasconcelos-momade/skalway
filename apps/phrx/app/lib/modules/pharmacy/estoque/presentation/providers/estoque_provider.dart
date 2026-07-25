import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/estoque_repository_impl.dart';
import '../../domain/entities/estoque_dashboard.dart';
import '../../domain/entities/estoque_item.dart';

class EstoqueListState {
  const EstoqueListState({
    this.dashboard,
    this.items = const <EstoqueItem>[],
    this.query = '',
    this.categoriaId,
    this.fornecedorId,
    this.estadoSanitario,
    this.disponibilidade,
    this.semStock,
    this.aExpirar,
    this.expirado,
    this.validadeDe,
    this.validadeAte,
    this.page = 1,
    this.pageSize = 10,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.actionLoteId,
  });

  final EstoqueDashboard? dashboard;
  final List<EstoqueItem> items;
  final String query;
  final String? categoriaId;
  final String? fornecedorId;
  final String? estadoSanitario;
  final String? disponibilidade;
  final bool? semStock;
  final bool? aExpirar;
  final bool? expirado;
  final String? validadeDe;
  final String? validadeAte;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final String? actionLoteId;

  bool get hasFilters =>
      categoriaId != null ||
      fornecedorId != null ||
      estadoSanitario != null ||
      disponibilidade != null ||
      semStock == true ||
      aExpirar == true ||
      expirado == true ||
      (validadeDe != null && validadeDe!.isNotEmpty) ||
      (validadeAte != null && validadeAte!.isNotEmpty);

  EstoqueListState copyWith({
    EstoqueDashboard? dashboard,
    List<EstoqueItem>? items,
    String? query,
    String? categoriaId,
    bool clearCategoriaId = false,
    String? fornecedorId,
    bool clearFornecedorId = false,
    String? estadoSanitario,
    bool clearEstadoSanitario = false,
    String? disponibilidade,
    bool clearDisponibilidade = false,
    bool? semStock,
    bool clearSemStock = false,
    bool? aExpirar,
    bool clearAExpirar = false,
    bool? expirado,
    bool clearExpirado = false,
    String? validadeDe,
    bool clearValidadeDe = false,
    String? validadeAte,
    bool clearValidadeAte = false,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
    String? actionLoteId,
    bool clearActionLoteId = false,
  }) {
    return EstoqueListState(
      dashboard: dashboard ?? this.dashboard,
      items: items ?? this.items,
      query: query ?? this.query,
      categoriaId: clearCategoriaId ? null : (categoriaId ?? this.categoriaId),
      fornecedorId:
          clearFornecedorId ? null : (fornecedorId ?? this.fornecedorId),
      estadoSanitario: clearEstadoSanitario
          ? null
          : (estadoSanitario ?? this.estadoSanitario),
      disponibilidade: clearDisponibilidade
          ? null
          : (disponibilidade ?? this.disponibilidade),
      semStock: clearSemStock ? null : (semStock ?? this.semStock),
      aExpirar: clearAExpirar ? null : (aExpirar ?? this.aExpirar),
      expirado: clearExpirado ? null : (expirado ?? this.expirado),
      validadeDe: clearValidadeDe ? null : (validadeDe ?? this.validadeDe),
      validadeAte: clearValidadeAte ? null : (validadeAte ?? this.validadeAte),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionLoteId:
          clearActionLoteId ? null : (actionLoteId ?? this.actionLoteId),
    );
  }
}

class _EstoqueCacheEntry {
  _EstoqueCacheEntry({
    required this.response,
    required this.cachedAt,
  });

  final PaginationResponse<EstoqueItem> response;
  final DateTime cachedAt;
}

class EstoqueListController extends Notifier<EstoqueListState> {
  Timer? _debounce;
  int _requestId = 0;
  static final Map<String, _EstoqueCacheEntry> _cache = {};

  /// Aplica delta de stock a um lote visível na lista (feedback imediato na UI).
  void applyLoteStockDelta({required String loteId, required num delta}) {
    if (delta == 0) return;

    final items = state.items.map((item) {
      if (item.id != loteId) return item;
      return EstoqueItem(
        id: item.id,
        produtoId: item.produtoId,
        produtoNomeComercial: item.produtoNomeComercial,
        produtoNomeGenerico: item.produtoNomeGenerico,
        produtoDosagem: item.produtoDosagem,
        produtoFormaFarmaceutica: item.produtoFormaFarmaceutica,
        produtoBarcode: item.produtoBarcode,
        categoriaId: item.categoriaId,
        categoriaNome: item.categoriaNome,
        fornecedorId: item.fornecedorId,
        fornecedorNome: item.fornecedorNome,
        numeroLote: item.numeroLote,
        dataValidade: item.dataValidade,
        diasRestantes: item.diasRestantes,
        indicadorValidade: item.indicadorValidade,
        indicadorStock: item.indicadorStock,
        quantidadeDisponivel: item.quantidadeDisponivel + delta,
        quantidadeTotal: item.quantidadeTotal + delta,
        quantidadeInicial: item.quantidadeInicial,
        quantidadeQuarentena: item.quantidadeQuarentena,
        quantidadeIncinerada: item.quantidadeIncinerada,
        precoCompra: item.precoCompra,
        precoVenda: item.precoVenda,
        estadoSanitario: item.estadoSanitario,
        estadoSanitarioEfetivo: item.estadoSanitarioEfetivo,
        acoesPermitidas: item.acoesPermitidas,
        disponibilidade: item.disponibilidade,
        ultimaAtualizacao: item.ultimaAtualizacao,
        estoqueMinimo: item.estoqueMinimo,
      );
    }).toList();

    state = state.copyWith(items: items);
  }

  /// Limpa cache local e força recarregamento.
  ///
  /// Usar após mutations (criar lote, entrada, ajustes) para evitar UI stale.
  Future<void> syncAfterMutation() async {
    _cache.clear();
    await load(force: true);
  }

  @override
  EstoqueListState build() {
    ref.onDispose(() => _debounce?.cancel());

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;

      if (!isReady) {
        _cache.clear();
        state = const EstoqueListState();
        return;
      }

      final tenantChanged =
          previous?.session?.tenantId != next.session?.tenantId ||
          previous?.session?.branchId != next.session?.branchId;

      if (isReady && (!wasReady || tenantChanged)) {
        unawaited(load(force: true));
      }
    });

    if (authReady) {
      Future.microtask(load);
    }
    return const EstoqueListState();
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) return;

    _debounce?.cancel();
    state = state.copyWith(query: normalized, page: 1, clearError: true);

    _debounce = Timer(const Duration(milliseconds: 350), () {
      load();
    });
  }

  void setCategoriaFilter(String? categoriaId) {
    if (state.categoriaId == categoriaId) return;
    _debounce?.cancel();
    state = state.copyWith(
      categoriaId: categoriaId,
      clearCategoriaId: categoriaId == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setFornecedorFilter(String? fornecedorId) {
    if (state.fornecedorId == fornecedorId) return;
    _debounce?.cancel();
    state = state.copyWith(
      fornecedorId: fornecedorId,
      clearFornecedorId: fornecedorId == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setEstadoSanitarioFilter(String? value) {
    if (state.estadoSanitario == value) return;
    state = state.copyWith(
      estadoSanitario: value,
      clearEstadoSanitario: value == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setDisponibilidadeFilter(String? value) {
    if (state.disponibilidade == value) return;
    state = state.copyWith(
      disponibilidade: value,
      clearDisponibilidade: value == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setSemStockFilter(bool? value) {
    if (state.semStock == value) return;
    state = state.copyWith(
      semStock: value,
      clearSemStock: value == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setAExpirarFilter(bool? value) {
    if (state.aExpirar == value) return;
    state = state.copyWith(
      aExpirar: value,
      clearAExpirar: value == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setExpiradoFilter(bool? value) {
    if (state.expirado == value) return;
    state = state.copyWith(
      expirado: value,
      clearExpirado: value == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setValidadeRange({String? de, String? ate}) {
    state = state.copyWith(
      validadeDe: de,
      clearValidadeDe: de == null,
      validadeAte: ate,
      clearValidadeAte: ate == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void clearFilters() {
    if (!state.hasFilters) return;
    _debounce?.cancel();
    state = state.copyWith(
      clearCategoriaId: true,
      clearFornecedorId: true,
      clearEstadoSanitario: true,
      clearDisponibilidade: true,
      clearSemStock: true,
      clearAExpirar: true,
      clearExpirado: true,
      clearValidadeDe: true,
      clearValidadeAte: true,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await load();
  }

  void setPageSize(int pageSize) {
    if (pageSize < 1 || pageSize == state.pageSize) return;
    state = state.copyWith(
      pageSize: pageSize,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  Future<void> refreshCurrentPage() async {
    await load(force: true);
  }

  void setActionLoteId(String? loteId) {
    state = state.copyWith(
      actionLoteId: loteId,
      clearActionLoteId: loteId == null,
    );
  }

  Future<void> load({bool force = false}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      state = const EstoqueListState();
      return;
    }

    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(estoqueRepositoryProvider);
      final cacheKey = _cacheKey(state);

      PaginationResponse<EstoqueItem>? searchResult;
      EstoqueDashboard? dashboardResult = state.dashboard;

      final dashboardFuture = repository.fetchDashboard().then((value) {
        dashboardResult = value;
      }).catchError((_) {});

      if (!force) {
        final cached = _cache[cacheKey];
        if (cached != null &&
            DateTime.now().difference(cached.cachedAt) <
                const Duration(seconds: 30)) {
          await dashboardFuture;
          if (requestId != _requestId) return;
          state = state.copyWith(
            dashboard: dashboardResult,
            items: List<EstoqueItem>.of(cached.response.items),
            page: cached.response.page,
            pageSize: cached.response.pageSize,
            hasMore: cached.response.hasMore,
            totalCount: cached.response.totalCount,
            isLoading: false,
            isInitialized: true,
            clearError: true,
          );
          return;
        }
      }

      try {
        searchResult = await repository.search(
          query: state.query.isEmpty ? null : state.query,
          categoriaId: state.categoriaId,
          fornecedorId: state.fornecedorId,
          estadoSanitario: state.estadoSanitario,
          disponibilidade: state.disponibilidade,
          semStock: state.semStock,
          aExpirar: state.aExpirar,
          expirado: state.expirado,
          validadeDe: state.validadeDe,
          validadeAte: state.validadeAte,
          page: state.page,
          pageSize: state.pageSize,
        );
      } on ApiFailure catch (e) {
        if (requestId != _requestId) return;
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          errorMessage: e.message,
        );
        return;
      }

      await dashboardFuture;

      if (requestId != _requestId) return;

      final response = searchResult;

      _cache[cacheKey] = _EstoqueCacheEntry(
        response: response,
        cachedAt: DateTime.now(),
      );

      state = state.copyWith(
        dashboard: dashboardResult,
        items: List<EstoqueItem>.of(response.items),
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  String _cacheKey(EstoqueListState current) {
    return [
      current.query,
      current.categoriaId ?? '',
      current.fornecedorId ?? '',
      current.estadoSanitario ?? '',
      current.disponibilidade ?? '',
      current.semStock?.toString() ?? '',
      current.aExpirar?.toString() ?? '',
      current.expirado?.toString() ?? '',
      current.validadeDe ?? '',
      current.validadeAte ?? '',
      current.page,
      current.pageSize,
    ].join('|');
  }
}

final estoqueListProvider =
    NotifierProvider<EstoqueListController, EstoqueListState>(
  EstoqueListController.new,
);
