import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventario_provider.dart';
import '../providers/inventory_catalog_provider.dart';
import '../widgets/inventory_mobile_layout.dart';
import '../widgets/inventory_products_tab.dart';

String _formatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class InventoryHubPage extends ConsumerStatefulWidget {
  const InventoryHubPage({super.key});

  @override
  ConsumerState<InventoryHubPage> createState() => _InventoryHubPageState();
}

class _InventoryHubPageState extends ConsumerState<InventoryHubPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(inventoryCatalogProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    await ref.read(inventarioProvider.notifier).refreshLists();
    final activeInventory = ref.read(inventarioProvider).activeInventory;
    if (activeInventory != null) {
      await ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage();
    }
  }

  Future<void> _startInventory() async {
    final result = await showNovoInventarioDialog(context);
    if (!mounted || result == null) {
      return;
    }

    await ref
        .read(inventarioProvider.notifier)
        .startInventory(observacao: result.observacao);
    await ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage();
  }

  Future<void> _handleCatalogItem(InventarioItem item) async {
    final state = ref.read(inventarioProvider);
    if (!state.canRecordCount) {
      PharmaFeedback.error(
        context,
        'Inicie ou seleccione um inventario em contagem antes de adicionar itens.',
      );
      return;
    }

    final estoqueContado = await showInventarioCountDialog(context, item: item);

    if (!mounted || estoqueContado == null) {
      return;
    }

    await ref
        .read(inventarioProvider.notifier)
        .recordCount(item: item, estoqueContado: estoqueContado);
    await ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage();
  }

  Future<void> _confirmReconcile() async {
    final state = ref.read(inventarioProvider);
    if (!state.canReconcile) {
      return;
    }

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Reconciliar inventario',
      message:
          'A reconciliacao vai ajustar o stock conforme as contagens registadas. Deseja continuar?',
      confirmText: 'Reconciliar',
      cancelText: 'Cancelar',
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(inventarioProvider.notifier).reconcileActiveInventory();
  }

  Future<void> _confirmCancel() async {
    final state = ref.read(inventarioProvider);
    if (!state.canCancel) {
      return;
    }

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Cancelar inventario',
      message: 'Deseja cancelar o inventario activo?',
      confirmText: 'Cancelar inventario',
      cancelText: 'Voltar',
      destructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(inventarioProvider.notifier).cancelActiveInventory();
  }

  Future<void> _openMobileInventoryDetail() {
    final inventoryId = ref.read(inventarioProvider).activeInventory?.id;
    return AdaptiveNavigator.open<void>(
      context: context,
      fullscreenDialog: true,
      routeSettings: RouteSettings(
        name: '/inventario/${inventoryId ?? 'detalhe'}',
      ),
      builder: (_) => InventoryMobileDetailPage(
        onEditItem: _handleCatalogItem,
        onReconcile: _confirmReconcile,
        onCancel: _confirmCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final inventoryState = ref.watch(inventarioProvider);
    final inventoryController = ref.read(inventarioProvider.notifier);

    ref.listen<InventarioState>(inventarioProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaFeedback.success(context, next.successMessage!);
      }
    });

    final leftPane = _LeftPane(
      activeTab: inventoryState.activeTab,
      inventoryState: inventoryState,
      searchController: _searchController,
      canAddItems:
          inventoryState.canRecordCount &&
          !inventoryState.isRecordingCount &&
          !inventoryState.isReconciling,
      onTabChanged: inventoryController.setActiveTab,
      onSelectProduct: _handleCatalogItem,
      onSelectPendingInventory: inventoryController.selectPendingInventory,
      onSelectCompletedInventory: inventoryController.selectCompletedInventory,
    );

    final pageBody = isMobile
        ? leftPane
        : SizedBox(
            height: 760,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: leftPane),
                SizedBox(width: s.lg),
                Expanded(
                  flex: 5,
                  child: _RightPane(
                    state: inventoryState,
                    onEditItem: _handleCatalogItem,
                    onReconcile: _confirmReconcile,
                    onCancel: _confirmCancel,
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: inventoryState.isCreating ? null : _startInventory,
              icon: inventoryState.isCreating
                  ? const PharmaButtonLoader()
                  : const Icon(Icons.add_rounded),
              label: const Text('Iniciar Inventario'),
            )
          : null,
      bottomNavigationBar: isMobile && inventoryState.activeInventory != null
          ? SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(s.xs, 0, s.xs, s.xs),
                child: InventoryMobileSummaryBar(
                  inventory: inventoryState.activeInventory!,
                  recordedCount: inventoryState.recordedItems.length,
                  onOpen: _openMobileInventoryDetail,
                ),
              ),
            )
          : null,
      body: ModulePageFrame(
        scrollable: !isMobile,
        actions: isMobile
            ? const <Widget>[]
            : [
                OutlinedButton.icon(
                  onPressed: _refreshPage,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar'),
                ),
                FilledButton.icon(
                  onPressed: inventoryState.isCreating ? null : _startInventory,
                  icon: inventoryState.isCreating
                      ? const PharmaButtonLoader()
                      : const Icon(Icons.add_rounded),
                  label: const Text('Iniciar Inventario'),
                ),
              ],
        child: pageBody,
      ),
    );
  }
}

class InventoryMobileDetailPage extends ConsumerWidget {
  const InventoryMobileDetailPage({
    super.key,
    required this.onEditItem,
    required this.onReconcile,
    required this.onCancel,
  });

  final Future<void> Function(InventarioItem item) onEditItem;
  final Future<void> Function() onReconcile;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final state = ref.watch(inventarioProvider);

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(onPressed: () => AdaptiveNavigator.close(context)),
        title: const Text('Detalhe do Inventário'),
      ),
      body: SafeArea(
        child: _RightPane(
          state: state,
          fullscreen: true,
          onEditItem: onEditItem,
          onReconcile: onReconcile,
          onCancel: onCancel,
        ),
      ),
    );
  }
}

class _LeftPane extends StatefulWidget {
  const _LeftPane({
    required this.activeTab,
    required this.inventoryState,
    required this.searchController,
    required this.canAddItems,
    required this.onTabChanged,
    required this.onSelectProduct,
    required this.onSelectPendingInventory,
    required this.onSelectCompletedInventory,
  });

  final InventarioTab activeTab;
  final InventarioState inventoryState;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<InventarioTab> onTabChanged;
  final ValueChanged<InventarioItem> onSelectProduct;
  final ValueChanged<String> onSelectPendingInventory;
  final ValueChanged<String> onSelectCompletedInventory;

  @override
  State<_LeftPane> createState() => _LeftPaneState();
}

class _LeftPaneState extends State<_LeftPane>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _indexForTab(widget.activeTab),
    );
  }

  @override
  void didUpdateWidget(_LeftPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexForTab(widget.activeTab);
    if (oldWidget.activeTab != widget.activeTab &&
        _tabController.index != nextIndex) {
      _tabController.index = nextIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _indexForTab(InventarioTab tab) {
    return switch (tab) {
      InventarioTab.produtos => 0,
      InventarioTab.pendentes => 1,
      InventarioTab.concluidos => 2,
    };
  }

  InventarioTab _tabForIndex(int index) {
    return switch (index) {
      0 => InventarioTab.produtos,
      1 => InventarioTab.pendentes,
      2 => InventarioTab.concluidos,
      _ => InventarioTab.produtos,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: TabBar(
            controller: _tabController,
            onTap: (index) => widget.onTabChanged(_tabForIndex(index)),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Produtos'),
              Tab(
                text:
                    'Em Contagem (${widget.inventoryState.pendingInventories.length})',
              ),
              Tab(
                text:
                    'Conciliados (${widget.inventoryState.completedInventories.length})',
              ),
            ],
          ),
        ),
        SizedBox(height: s.md),
        Expanded(
          child: switch (widget.activeTab) {
            InventarioTab.produtos => InventoryProductsTab(
              searchController: widget.searchController,
              canAddItems: widget.canAddItems,
              onSelectProduct: widget.onSelectProduct,
            ),
            InventarioTab.pendentes => _InventariosTab(
              title: 'Inventarios em contagem',
              subtitle:
                  'Seleccione um inventario em contagem para carregar os itens e voltar automaticamente para a tab Produtos.',
              isLoading: widget.inventoryState.isLoadingLists,
              inventories: widget.inventoryState.pendingInventories,
              activeInventoryId: widget.inventoryState.activeInventory?.id,
              emptyTitle: 'Nenhum inventario pendente',
              emptySubtitle:
                  'Inicie um inventario para criar o registo no backend.',
              onSelect: widget.onSelectPendingInventory,
            ),
            InventarioTab.concluidos => _InventariosTab(
              title: 'Inventarios conciliados',
              subtitle:
                  'Apenas visualizacao. Abra um card para consultar o inventario no painel da direita.',
              isLoading: widget.inventoryState.isLoadingLists,
              inventories: widget.inventoryState.completedInventories,
              activeInventoryId: widget.inventoryState.activeInventory?.id,
              emptyTitle: 'Nenhum inventario concluido',
              emptySubtitle:
                  'Os inventarios reconciliados aparecerao aqui automaticamente.',
              onSelect: widget.onSelectCompletedInventory,
            ),
          },
        ),
      ],
    );
  }
}

class _InventariosTab extends StatelessWidget {
  const _InventariosTab({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.inventories,
    required this.activeInventoryId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final bool isLoading;
  final List<InventarioResumo> inventories;
  final String? activeInventoryId;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.erpSectionTitle.copyWith(color: t.textPrimary),
        ),
        SizedBox(height: s.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
        SizedBox(height: s.sm),
        if (isLoading) const LinearProgressIndicator(),
        SizedBox(height: s.sm),
        Expanded(
          child: inventories.isEmpty
              ? _EmptyPane(
                  icon: Icons.assignment_outlined,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                )
              : ListView.separated(
                  itemCount: inventories.length,
                  separatorBuilder: (_, _) => SizedBox(height: s.sm),
                  itemBuilder: (context, index) {
                    final inventory = inventories[index];
                    return _InventarioResumoCard(
                      inventory: inventory,
                      selected: inventory.id == activeInventoryId,
                      onTap: () => onSelect(inventory.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InventarioResumoCard extends StatelessWidget {
  const _InventarioResumoCard({
    required this.inventory,
    required this.selected,
    required this.onTap,
  });

  final InventarioResumo inventory;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final accent = inventory.status == InventarioStatus.reconciliado
        ? t.brandGreen
        : t.posWarning;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: selected ? t.brandBlue.withValues(alpha: 0.08) : t.bgPrimary,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: selected ? t.brandBlue.withValues(alpha: 0.4) : t.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inventory.codigo,
                    style: Theme.of(
                      context,
                    ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                  ),
                ),
                _InfoTag(label: inventory.status.label, color: accent),
              ],
            ),
            SizedBox(height: s.sm),
            Text(
              'Data: ${_formatDate(inventory.iniciadoEm)}',
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            Text(
              'Itens: ${inventory.totalItens} | Divergencias: ${inventory.itensComDivergencia}',
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            if (inventory.observacao != null &&
                inventory.observacao!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: s.xs),
                child: Text(
                  inventory.observacao!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.erpCaption.copyWith(color: t.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.state,
    required this.onEditItem,
    required this.onReconcile,
    required this.onCancel,
    this.fullscreen = false,
  });

  final InventarioState state;
  final Future<void> Function(InventarioItem item) onEditItem;
  final Future<void> Function() onReconcile;
  final Future<void> Function() onCancel;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final activeInventory = state.activeInventory;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!fullscreen)
          Row(
            children: [
              Expanded(
                child: Text(
                  activeInventory == null
                      ? 'Novo Inventario'
                      : activeInventory.codigo,
                  style: Theme.of(
                    context,
                  ).textTheme.erpPageTitle.copyWith(color: t.textPrimary),
                ),
              ),
              if (state.isLoadingActive ||
                  state.isRecordingCount ||
                  state.isReconciling ||
                  state.isCancelling)
                const PharmaButtonLoader(),
            ],
          ),
        if (!fullscreen) SizedBox(height: s.lg),
        if (activeInventory == null)
          const Expanded(
            child: _EmptyPane(
              icon: Icons.fact_check_outlined,
              title: 'Nenhum inventario activo',
              subtitle:
                  'Inicie ou seleccione um inventario para adicionar contagens.',
            ),
          )
        else ...[
          _ActiveInventoryHeader(inventory: activeInventory),
          SizedBox(height: s.md),
          Expanded(
            child: state.recordedItems.isEmpty
                ? const _EmptyPane(
                    icon: Icons.playlist_add_check_outlined,
                    title: 'Lista vazia',
                    subtitle:
                        'Seleccione lotes na lista para registar a contagem.',
                  )
                : _InventoryRecordedTable(
                    items: state.recordedItems,
                    isEditable: state.canRecordCount,
                    onEdit: onEditItem,
                  ),
          ),
        ],
        SizedBox(height: s.md),
        _InventoryFooter(
          state: state,
          activeInventory: activeInventory,
          onCancel: onCancel,
          onReconcile: onReconcile,
        ),
      ],
    );

    if (fullscreen) {
      return Padding(padding: EdgeInsets.all(s.md), child: content);
    }

    return Container(
      padding: EdgeInsets.all(s.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _ActiveInventoryHeader extends StatelessWidget {
  const _ActiveInventoryHeader({required this.inventory});

  final InventarioDetalhe inventory;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final statusColor = inventory.status == InventarioStatus.reconciliado
        ? t.brandGreen
        : t.posWarning;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inventory.codigo,
            style: Theme.of(
              context,
            ).textTheme.erpPageTitle.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              _InfoTag(label: inventory.status.label, color: statusColor),
              _InfoTag(
                label: 'Data ${_formatDate(inventory.iniciadoEm)}',
                color: t.brandBlue,
              ),
              _InfoTag(
                label: 'Itens ${inventory.totalItens}',
                color: t.textMuted,
              ),
              _InfoTag(
                label: 'Divergencias ${inventory.itensComDivergencia}',
                color: inventory.itensComDivergencia > 0
                    ? t.posDanger
                    : t.brandGreen,
              ),
            ],
          ),
          if (inventory.observacao != null && inventory.observacao!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: s.sm),
              child: Text(
                inventory.observacao!,
                style: Theme.of(
                  context,
                ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryRecordedTable extends StatelessWidget {
  const _InventoryRecordedTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
  });

  final List<InventarioItem> items;
  final bool isEditable;
  final Future<void> Function(InventarioItem item) onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 768) {
          return _InventoryRecordedCardList(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
          );
        }

        if (width < 1200) {
          return _InventoryRecordedTabletTable(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
          );
        }

        return _InventoryRecordedDesktopTable(
          items: items,
          isEditable: isEditable,
          onEdit: onEdit,
        );
      },
    );
  }
}

class _InventoryRecordedDesktopTable extends StatelessWidget {
  const _InventoryRecordedDesktopTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
  });

  final List<InventarioItem> items;
  final bool isEditable;
  final Future<void> Function(InventarioItem item) onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1080,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.lg,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Estoque Sistema')),
                DataColumn(label: Text('Estoque Contado')),
                DataColumn(label: Text('Divergencia')),
                DataColumn(label: Text('Accoes')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(width: 260, child: Text(item.produtoNome)),
                    ),
                    DataCell(
                      SizedBox(width: 150, child: Text(item.numeroLote ?? '-')),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(_formatQuantity(item.estoqueSistema)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(_formatQuantity(item.estoqueContado)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(_formatQuantity(item.divergencia)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: IconButton(
                          onPressed: isEditable ? () => onEdit(item) : null,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar item',
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryRecordedTabletTable extends StatelessWidget {
  const _InventoryRecordedTabletTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
  });

  final List<InventarioItem> items;
  final bool isEditable;
  final Future<void> Function(InventarioItem item) onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.md,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Contado')),
                DataColumn(label: Text('Divergencia')),
                DataColumn(label: Text('Accoes')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 280,
                        child: Tooltip(
                          message:
                              'Sistema: ${_formatQuantity(item.estoqueSistema)}\nFornecedor: ${item.fornecedorNome ?? '-'}',
                          child: Text(
                            item.produtoNome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(width: 130, child: Text(item.numeroLote ?? '-')),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(_formatQuantity(item.estoqueContado)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(_formatQuantity(item.divergencia)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: IconButton(
                          onPressed: isEditable ? () => onEdit(item) : null,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar item',
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryRecordedCardList extends StatelessWidget {
  const _InventoryRecordedCardList({
    required this.items,
    required this.isEditable,
    required this.onEdit,
  });

  final List<InventarioItem> items;
  final bool isEditable;
  final Future<void> Function(InventarioItem item) onEdit;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _RecordedItemCard(
          item: item,
          editable: isEditable,
          onEdit: () => onEdit(item),
        );
      },
    );
  }
}

class _RecordedItemCard extends StatelessWidget {
  const _RecordedItemCard({
    required this.item,
    required this.editable,
    required this.onEdit,
  });

  final InventarioItem item;
  final bool editable;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final divergenciaColor = item.hasDivergencia ? t.posDanger : t.brandGreen;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.produtoNome,
                  style: Theme.of(
                    context,
                  ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                ),
              ),
              if (editable)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar contagem',
                ),
            ],
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.md,
            runSpacing: s.sm,
            children: [
              _RecordedItemInfo(label: 'Lote', value: item.numeroLote ?? '-'),
              _RecordedItemInfo(
                label: 'Sistema',
                value: _formatQuantity(item.estoqueSistema),
              ),
              _RecordedItemInfo(
                label: 'Contado',
                value: _formatQuantity(item.estoqueContado),
              ),
              _RecordedItemInfo(
                label: 'Divergencia',
                value: _formatQuantity(item.divergencia),
                color: divergenciaColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordedItemInfo extends StatelessWidget {
  const _RecordedItemInfo({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return RichText(
      text: TextSpan(
        style: textTheme.erpCaption.copyWith(color: color ?? t.textMuted),
        children: [
          TextSpan(
            text: '$label: ',
            style: textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _InventoryFooter extends StatelessWidget {
  const _InventoryFooter({
    required this.state,
    required this.activeInventory,
    required this.onCancel,
    required this.onReconcile,
  });

  final InventarioState state;
  final InventarioDetalhe? activeInventory;
  final Future<void> Function() onCancel;
  final Future<void> Function() onReconcile;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final helperText = switch (activeInventory?.status) {
      null => 'Inicie um inventario para habilitar accoes.',
      InventarioStatus.aberto => 'Inicie a contagem para registar itens.',
      InventarioStatus.emContagem =>
        state.recordedItems.isEmpty
            ? 'Adicione itens para reconciliar o inventario.'
            : 'Itens registados: ${state.recordedItems.length}',
      InventarioStatus.reconciliado => 'Inventario concluido.',
      InventarioStatus.cancelado => 'Inventario cancelado.',
    };
    final emphasized =
        activeInventory?.status == InventarioStatus.emContagem &&
        state.recordedItems.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helperText,
            style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
              color: emphasized ? t.textPrimary : t.textMuted,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          SizedBox(height: s.md),
          Row(
            children: [
              if (state.canCancel)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isCancelling ? null : onCancel,
                    icon: state.isCancelling
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                ),
              if (state.canCancel && state.canReconcile) SizedBox(width: s.md),
              if (state.canReconcile)
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: state.isReconciling ? null : onReconcile,
                    icon: state.isReconciling
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      state.isReconciling
                          ? 'A reconciliar...'
                          : 'Reconciliar Inventario',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.erpLabel.copyWith(color: t.textPrimary),
      ),
    );
  }
}

class NovoInventarioDialogResult {
  const NovoInventarioDialogResult({required this.observacao});

  final String observacao;
}

Future<NovoInventarioDialogResult?> showNovoInventarioDialog(
  BuildContext context,
) {
  return AdaptiveNavigator.openEmbeddedForm<NovoInventarioDialogResult>(
    context: context,
    title: const Text('Novo Inventario'),
    routeSettings: const RouteSettings(name: '/inventario/novo'),
    formBuilder: (ctx, {required embedded}) =>
        _NovoInventarioDialog(embedded: embedded),
  );
}

Future<double?> showInventarioCountDialog(
  BuildContext context, {
  required InventarioItem item,
}) {
  final title = Text(
    item.estoqueContado != 0 || item.divergencia != 0
        ? 'Actualizar ${item.produtoNome}'
        : 'Adicionar ao Inventario',
  );
  return AdaptiveNavigator.openEmbeddedForm<double>(
    context: context,
    title: title,
    routeSettings: RouteSettings(name: '/inventario/itens/${item.id}/contagem'),
    formBuilder: (ctx, {required embedded}) =>
        _InventarioCountDialog(item: item, embedded: embedded),
  );
}

class _NovoInventarioDialog extends StatefulWidget {
  const _NovoInventarioDialog({this.embedded = false});

  final bool embedded;

  @override
  State<_NovoInventarioDialog> createState() => _NovoInventarioDialogState();
}

class _NovoInventarioDialogState extends State<_NovoInventarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    AdaptiveNavigator.complete(
      context,
      NovoInventarioDialogResult(observacao: _observacaoController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _observacaoController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observacao',
              hintText: 'Ex.: Contagem ciclica da seccao A',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: s.sm),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Os lotes serao carregados automaticamente no inventario activo.',
            ),
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Iniciar'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Novo Inventario'),
      content: form,
      actions: actions,
    );
  }
}

class _InventarioCountDialog extends StatefulWidget {
  const _InventarioCountDialog({required this.item, this.embedded = false});

  final InventarioItem item;
  final bool embedded;

  bool get hasExistingCount =>
      item.estoqueContado != 0 || item.divergencia != 0;

  @override
  State<_InventarioCountDialog> createState() => _InventarioCountDialogState();
}

class _InventarioCountDialogState extends State<_InventarioCountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _produtoController;
  late final TextEditingController _loteController;
  late final TextEditingController _estoqueSistemaController;
  late final TextEditingController _estoqueContadoController;
  late final TextEditingController _divergenciaController;

  @override
  void initState() {
    super.initState();
    _produtoController = TextEditingController(text: widget.item.produtoNome);
    _loteController = TextEditingController(
      text: widget.item.numeroLote ?? '-',
    );
    _estoqueSistemaController = TextEditingController(
      text: _formatQuantity(widget.item.estoqueSistema),
    );
    _estoqueContadoController = TextEditingController(
      text: widget.item.estoqueContado == 0
          ? ''
          : _formatQuantity(widget.item.estoqueContado),
    );
    _divergenciaController = TextEditingController(
      text: widget.item.divergencia == 0
          ? 'Calculada pelo backend apos guardar'
          : _formatQuantity(widget.item.divergencia),
    );
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _loteController.dispose();
    _estoqueSistemaController.dispose();
    _estoqueContadoController.dispose();
    _divergenciaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    AdaptiveNavigator.complete(
      context,
      double.parse(_estoqueContadoController.text.trim().replaceAll(',', '.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogField(
            controller: _produtoController,
            label: 'Produto',
            hint: '-',
            readOnly: true,
          ),
          SizedBox(height: s.md),
          _DialogField(
            controller: _loteController,
            label: 'Lote',
            hint: '-',
            readOnly: true,
          ),
          SizedBox(height: s.md),
          _DialogField(
            controller: _estoqueSistemaController,
            label: 'Estoque Sistema',
            hint: '-',
            readOnly: true,
          ),
          SizedBox(height: s.md),
          _DialogField(
            controller: _estoqueContadoController,
            label: 'Estoque Contado',
            hint: 'Ex.: 12',
            validator: _quantityValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
          ),
          SizedBox(height: s.md),
          _DialogField(
            controller: _divergenciaController,
            label: 'Divergencia',
            hint: 'Calculada pelo backend',
            readOnly: true,
          ),
          SizedBox(height: s.sm),
          const Text(
            'A divergencia nao e calculada no frontend. O backend recalcula e actualiza a lista apos guardar.',
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Guardar'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(
        widget.hasExistingCount
            ? 'Actualizar ${widget.item.produtoNome}'
            : 'Adicionar ao Inventario',
      ),
      content: form,
      actions: actions,
    );
  }

  String? _quantityValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return 'Campo obrigatorio';
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return 'Informe uma quantidade valida';
    }
    return null;
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
