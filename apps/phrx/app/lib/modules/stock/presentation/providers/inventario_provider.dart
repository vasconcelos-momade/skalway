import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/inventory_catalog_cache_policy.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/entities/inventario.dart';

enum InventarioTab { produtos, pendentes, concluidos }

class InventarioState {
  const InventarioState({
    this.activeTab = InventarioTab.produtos,
    this.isLoadingLists = false,
    this.isLoadingActive = false,
    this.isCreating = false,
    this.isRecordingCount = false,
    this.isReconciling = false,
    this.isCancelling = false,
    this.successMessage,
    this.errorMessage,
    this.activeInventory,
    this.recordedItemIds = const <String>{},
    this.pendingInventories = const <InventarioResumo>[],
    this.completedInventories = const <InventarioResumo>[],
  });

  final InventarioTab activeTab;
  final bool isLoadingLists;
  final bool isLoadingActive;
  final bool isCreating;
  final bool isRecordingCount;
  final bool isReconciling;
  final bool isCancelling;
  final String? successMessage;
  final String? errorMessage;
  final InventarioDetalhe? activeInventory;
  final Set<String> recordedItemIds;
  final List<InventarioResumo> pendingInventories;
  final List<InventarioResumo> completedInventories;

  bool get isBusy =>
      isLoadingLists ||
      isLoadingActive ||
      isCreating ||
      isRecordingCount ||
      isReconciling ||
      isCancelling;

  bool get hasActiveInventory => activeInventory != null;

  bool get canRecordCount =>
      activeInventory != null && activeInventory!.status.canRecordCount;

  bool get canReconcile =>
      activeInventory != null && activeInventory!.status.canReconcile;

  bool get canCancel =>
      activeInventory != null && activeInventory!.status.isEditable;

  List<InventarioItem> get recordedItems {
    final items = activeInventory?.itens ?? const <InventarioItem>[];
    return items.where((item) => recordedItemIds.contains(item.id)).toList();
  }

  InventarioState copyWith({
    InventarioTab? activeTab,
    bool? isLoadingLists,
    bool? isLoadingActive,
    bool? isCreating,
    bool? isRecordingCount,
    bool? isReconciling,
    bool? isCancelling,
    String? successMessage,
    String? errorMessage,
    InventarioDetalhe? activeInventory,
    Set<String>? recordedItemIds,
    List<InventarioResumo>? pendingInventories,
    List<InventarioResumo>? completedInventories,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearActiveInventory = false,
    bool clearRecordedItems = false,
  }) {
    return InventarioState(
      activeTab: activeTab ?? this.activeTab,
      isLoadingLists: isLoadingLists ?? this.isLoadingLists,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isCreating: isCreating ?? this.isCreating,
      isRecordingCount: isRecordingCount ?? this.isRecordingCount,
      isReconciling: isReconciling ?? this.isReconciling,
      isCancelling: isCancelling ?? this.isCancelling,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeInventory: clearActiveInventory
          ? null
          : (activeInventory ?? this.activeInventory),
      recordedItemIds: clearRecordedItems
          ? const <String>{}
          : (recordedItemIds ?? this.recordedItemIds),
      pendingInventories: pendingInventories ?? this.pendingInventories,
      completedInventories: completedInventories ?? this.completedInventories,
    );
  }
}

class InventarioController extends Notifier<InventarioState> {
  @override
  InventarioState build() {
    Future.microtask(refreshLists);
    return const InventarioState();
  }

  void setActiveTab(InventarioTab tab) {
    state = state.copyWith(activeTab: tab);
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
      final concluidos = await repository.listarInventarios(
        status: InventarioStatus.reconciliado,
      );

      final pending = <InventarioResumo>[...emContagem, ...abertos]
        ..sort((a, b) => b.iniciadoEm.compareTo(a.iniciadoEm));

      state = state.copyWith(
        isLoadingLists: false,
        pendingInventories: pending,
        completedInventories: concluidos,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoadingLists: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoadingLists: false, errorMessage: e.toString());
    }
  }

  Future<void> startInventory({required String observacao}) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
      clearRecordedItems: true,
    );

    try {
      final repository = ref.read(inventarioRepositoryProvider);
      final opened = await repository.abrirInventario(
        AbrirInventarioRequest(observacao: observacao),
      );
      final counting = opened.status == InventarioStatus.emContagem
          ? opened
          : await repository.iniciarContagem(opened.id);

      await refreshLists();
      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isCreating: false,
        activeTab: InventarioTab.produtos,
        activeInventory: counting,
        successMessage: 'Inventário ${counting.codigo} iniciado com sucesso.',
        clearError: true,
        clearRecordedItems: true,
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

  Future<void> selectPendingInventory(String inventarioId) async {
    await _loadInventory(inventarioId, tabAfterLoad: InventarioTab.produtos);
  }

  Future<void> selectCompletedInventory(String inventarioId) async {
    await _loadInventory(inventarioId, tabAfterLoad: InventarioTab.concluidos);
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
      InventoryCatalogCachePolicy.clear();

      final nextItems = active.itens
          .map(
            (current) => current.id == updatedItem.id ? updatedItem : current,
          )
          .toList();
      final divergencias = nextItems.where((i) => i.hasDivergencia).length;
      final nextRecorded = {...state.recordedItemIds, updatedItem.id};

      state = state.copyWith(
        isRecordingCount: false,
        activeInventory: active.copyWith(
          itens: nextItems,
          itensComDivergencia: divergencias,
        ),
        recordedItemIds: nextRecorded,
        successMessage: 'Contagem registada para ${updatedItem.produtoNome}.',
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

  Future<void> reconcileActiveInventory() async {
    final active = state.activeInventory;
    if (active == null || !active.status.canReconcile) {
      state = state.copyWith(
        errorMessage: 'Seleccione um inventário em contagem para reconciliar.',
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
      await refreshLists();
      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isReconciling: false,
        activeTab: InventarioTab.concluidos,
        activeInventory: updated,
        successMessage:
            'Inventário ${updated.codigo} reconciliado com sucesso.',
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
      await refreshLists();
      InventoryCatalogCachePolicy.clear();

      state = state.copyWith(
        isCancelling: false,
        clearActiveInventory: true,
        clearRecordedItems: true,
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

  Future<void> _loadInventory(
    String inventarioId, {
    required InventarioTab tabAfterLoad,
  }) async {
    state = state.copyWith(
      isLoadingActive: true,
      clearError: true,
      clearSuccess: true,
      clearRecordedItems: true,
    );

    try {
      final detail = await ref
          .read(inventarioRepositoryProvider)
          .obterInventario(inventarioId);
      final recorded = detail.itens
          .where(_isRecordedItem)
          .map((item) => item.id)
          .toSet();

      state = state.copyWith(
        isLoadingActive: false,
        activeTab: tabAfterLoad,
        activeInventory: detail,
        recordedItemIds: recorded,
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

  bool _isRecordedItem(InventarioItem item) {
    return item.estoqueContado != 0 || item.divergencia != 0;
  }
}

final inventarioProvider =
    NotifierProvider.autoDispose<InventarioController, InventarioState>(
      InventarioController.new,
    );
