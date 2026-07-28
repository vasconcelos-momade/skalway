import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/inventory_catalog_cache_policy.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/entities/inventario.dart';

class InventarioState {
  const InventarioState({
    this.isLoadingLists = false,
    this.isLoadingActive = false,
    this.isCreating = false,
    this.isRecordingCount = false,
    this.isRemovingItem = false,
    this.isReconciling = false,
    this.isCancelling = false,
    this.successMessage,
    this.errorMessage,
    this.activeInventory,
  });

  final bool isLoadingLists;
  final bool isLoadingActive;
  final bool isCreating;
  final bool isRecordingCount;
  final bool isRemovingItem;
  final bool isReconciling;
  final bool isCancelling;
  final String? successMessage;
  final String? errorMessage;
  final InventarioDetalhe? activeInventory;

  bool get isBusy =>
      isLoadingLists ||
      isLoadingActive ||
      isCreating ||
      isRecordingCount ||
      isRemovingItem ||
      isReconciling ||
      isCancelling;

  bool get hasOpenInventory {
    final status = activeInventory?.status;
    return status == InventarioStatus.aberto ||
        status == InventarioStatus.emContagem;
  }

  bool get canInventariar => hasOpenInventory;

  bool get canRecordCount =>
      activeInventory != null &&
      (activeInventory!.status == InventarioStatus.emContagem ||
          activeInventory!.status == InventarioStatus.aberto);

  bool get canReconcile =>
      activeInventory != null && activeInventory!.status.canReconcile;

  bool get canCancel =>
      activeInventory != null && activeInventory!.status.isEditable;

  List<InventarioItem> get inventariadosItems =>
      activeInventory?.itens ?? const <InventarioItem>[];

  int get produtosInventariadosCount {
    final ids = inventariadosItems.map((e) => e.produtoId).toSet();
    return ids.length;
  }

  int get divergenciasCount =>
      inventariadosItems.where((item) => item.hasDivergencia).length;

  InventarioState copyWith({
    bool? isLoadingLists,
    bool? isLoadingActive,
    bool? isCreating,
    bool? isRecordingCount,
    bool? isRemovingItem,
    bool? isReconciling,
    bool? isCancelling,
    String? successMessage,
    String? errorMessage,
    InventarioDetalhe? activeInventory,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearActiveInventory = false,
  }) {
    return InventarioState(
      isLoadingLists: isLoadingLists ?? this.isLoadingLists,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isCreating: isCreating ?? this.isCreating,
      isRecordingCount: isRecordingCount ?? this.isRecordingCount,
      isRemovingItem: isRemovingItem ?? this.isRemovingItem,
      isReconciling: isReconciling ?? this.isReconciling,
      isCancelling: isCancelling ?? this.isCancelling,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeInventory: clearActiveInventory
          ? null
          : (activeInventory ?? this.activeInventory),
    );
  }
}

class InventarioController extends Notifier<InventarioState> {
  @override
  InventarioState build() {
    Future.microtask(refreshLists);
    return const InventarioState();
  }

  Future<void> refreshLists() async {
    state = state.copyWith(isLoadingLists: true, clearError: true);

    try {
      final repository = ref.read(inventarioRepositoryProvider);
      final abertos = await repository.listarInventarios(
        status: InventarioStatus.aberto,
      );
      final emContagem = await repository.listarInventarios(
        status: InventarioStatus.emContagem,
      );

      final pending = <InventarioResumo>[...emContagem, ...abertos]
        ..sort((a, b) => b.iniciadoEm.compareTo(a.iniciadoEm));

      state = state.copyWith(isLoadingLists: false, clearError: true);

      if (pending.isNotEmpty) {
        final currentId = state.activeInventory?.id;
        if (currentId != null &&
            pending.any((item) => item.id == currentId)) {
          await _loadInventory(currentId);
        } else {
          await _loadInventory(pending.first.id);
        }
      } else if (state.activeInventory != null &&
          state.activeInventory!.status.isEditable) {
        state = state.copyWith(clearActiveInventory: true);
      }
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoadingLists: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoadingLists: false, errorMessage: e.toString());
    }
  }

  Future<void> startInventory({String? observacao}) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(inventarioRepositoryProvider);
      final opened = await repository.abrirInventario(
        AbrirInventarioRequest(observacao: observacao),
      );
      final counting = opened.status == InventarioStatus.emContagem
          ? opened
          : await repository.iniciarContagem(opened.id);

      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isCreating: false,
        activeInventory: counting,
        successMessage: 'Inventário ${counting.codigo} iniciado com sucesso.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> addItem({
    required String produtoId,
    required String loteId,
    required double estoqueContado,
    String? observacao,
  }) async {
    final active = state.activeInventory;
    if (active == null || !canInventariarFor(active)) {
      state = state.copyWith(
        errorMessage: 'Inicie um inventário antes de inventariar produtos.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isRecordingCount: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final created = await ref.read(inventarioRepositoryProvider).adicionarItem(
            inventarioId: active.id,
            request: AdicionarInventarioItemRequest(
              produtoId: produtoId,
              loteId: loteId,
              estoqueContado: estoqueContado,
              observacao: observacao,
            ),
          );

      final detail = await ref
          .read(inventarioRepositoryProvider)
          .obterInventario(active.id);

      state = state.copyWith(
        isRecordingCount: false,
        activeInventory: detail,
        successMessage: 'Lote adicionado ao inventário (${created.numeroLote}).',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isRecordingCount: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRecordingCount: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> recordCount({
    required InventarioItem item,
    required double estoqueContado,
  }) async {
    final active = state.activeInventory;
    if (active == null || !active.status.canRecordCount) {
      state = state.copyWith(
        errorMessage:
            'Seleccione um inventário em contagem para registar quantidades.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isRecordingCount: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updatedItem = await ref
          .read(inventarioRepositoryProvider)
          .registarContagem(
            inventarioId: active.id,
            itemId: item.id,
            estoqueContado: estoqueContado,
          );

      final nextItems = active.itens
          .map(
            (current) => current.id == updatedItem.id ? updatedItem : current,
          )
          .toList();
      final divergencias = nextItems.where((i) => i.hasDivergencia).length;

      state = state.copyWith(
        isRecordingCount: false,
        activeInventory: active.copyWith(
          itens: nextItems,
          totalItens: nextItems.length,
          itensComDivergencia: divergencias,
        ),
        successMessage: 'Contagem actualizada para ${updatedItem.produtoNome}.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isRecordingCount: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRecordingCount: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> removeItem(InventarioItem item) async {
    final active = state.activeInventory;
    if (active == null || !active.status.isEditable) {
      return;
    }

    state = state.copyWith(
      isRemovingItem: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await ref.read(inventarioRepositoryProvider).removerItem(
            inventarioId: active.id,
            itemId: item.id,
          );

      final nextItems =
          active.itens.where((current) => current.id != item.id).toList();
      final divergencias = nextItems.where((i) => i.hasDivergencia).length;

      state = state.copyWith(
        isRemovingItem: false,
        activeInventory: active.copyWith(
          itens: nextItems,
          totalItens: nextItems.length,
          itensComDivergencia: divergencias,
        ),
        successMessage: 'Item removido do inventário.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isRemovingItem: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRemovingItem: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> reconcileActiveInventory() async {
    final active = state.activeInventory;
    if (active == null || !active.status.canReconcile) {
      state = state.copyWith(
        errorMessage: 'Não há inventário em contagem para concluir.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isReconciling: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updated = await ref
          .read(inventarioRepositoryProvider)
          .reconciliar(active.id);
      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isReconciling: false,
        clearActiveInventory: true,
        successMessage:
            'Inventário ${updated.codigo} concluído com sucesso.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isReconciling: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isReconciling: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> cancelActiveInventory() async {
    final active = state.activeInventory;
    if (active == null || !active.status.isEditable) {
      return;
    }

    state = state.copyWith(
      isCancelling: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await ref.read(inventarioRepositoryProvider).cancelar(active.id);
      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isCancelling: false,
        clearActiveInventory: true,
        successMessage: 'Inventário cancelado.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> reloadActiveInventory() async {
    final id = state.activeInventory?.id;
    if (id == null) return;
    await _loadInventory(id);
  }

  bool canInventariarFor(InventarioDetalhe inventory) {
    return inventory.status == InventarioStatus.aberto ||
        inventory.status == InventarioStatus.emContagem;
  }

  Future<void> _loadInventory(String inventarioId) async {
    state = state.copyWith(
      isLoadingActive: true,
      clearError: true,
    );

    try {
      final detail = await ref
          .read(inventarioRepositoryProvider)
          .obterInventario(inventarioId);

      state = state.copyWith(
        isLoadingActive: false,
        activeInventory: detail,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoadingActive: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final inventarioProvider =
    NotifierProvider.autoDispose<InventarioController, InventarioState>(
      InventarioController.new,
    );
