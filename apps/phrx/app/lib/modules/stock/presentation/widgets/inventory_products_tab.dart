import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/table_typography.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventory_catalog_provider.dart';

String formatInventoryQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Tab Produtos do inventário — padrão Lotes (desktop tabela + paginação; mobile scroll infinito).
class InventoryProductsTab extends ConsumerStatefulWidget {
  const InventoryProductsTab({
    super.key,
    required this.searchController,
    required this.canAddItems,
    required this.onSelectProduct,
  });

  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<InventarioItem> onSelectProduct;

  @override
  ConsumerState<InventoryProductsTab> createState() =>
      _InventoryProductsTabState();
}

class _InventoryProductsTabState extends ConsumerState<InventoryProductsTab> {
  List<InventarioItem> _accumulatedItems = [];

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(inventoryCatalogProvider);
    final catalogController = ref.read(inventoryCatalogProvider.notifier);
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = MediaQuery.sizeOf(context).width <= 920;
    final resolvedTotal = catalogState.resolvedTotalCount;

    ref.listen<InventoryCatalogState>(inventoryCatalogProvider, (prev, next) {
      if (!mounted) return;

      if (prev?.inventoryId != next.inventoryId ||
          prev?.query != next.query ||
          prev?.pageSize != next.pageSize) {
        setState(() => _accumulatedItems = List.of(next.items));
        return;
      }

      if (prev?.page != next.page) {
        setState(() {
          if (next.page == 1) {
            _accumulatedItems = List.of(next.items);
          } else {
            final newItems = next.items
                .where((item) => !_accumulatedItems.any((a) => a.id == item.id))
                .toList();
            _accumulatedItems = [..._accumulatedItems, ...newItems];
          }
        });
      } else if (prev?.items != next.items && next.page == 1) {
        setState(() => _accumulatedItems = List.of(next.items));
      }
    });

    if (widget.searchController.text != catalogState.query) {
      widget.searchController.value = TextEditingValue(
        text: catalogState.query,
        selection: TextSelection.collapsed(offset: catalogState.query.length),
      );
    }

    if (catalogState.inventoryId == null) {
      return const _InventoryProductsEmptyPane(
        icon: Icons.fact_check_outlined,
        title: 'Nenhum inventario activo',
        subtitle: 'Inicie ou seleccione um inventario para carregar os lotes.',
      );
    }

    if (isMobile) {
      return EnterpriseMobileScrollList(
        errorText: catalogState.errorMessage,
        stickyHeader: EnterpriseMobileToolbar(
          searchController: widget.searchController,
          searchHint: 'Nome, substancia activa ou fornecedor...',
          enabled: !catalogState.isLoading,
          isLoading: catalogState.isLoading,
          hasFilters: catalogState.query.isNotEmpty,
          showFiltersButton: false,
          onSearchSubmitted: catalogController.onSearchChanged,
          onOpenFilters: () {},
          onClearFilters: () async => catalogController.onSearchChanged(''),
          onRefresh: catalogController.refreshCurrentPage,
        ),
        itemCount: _accumulatedItems.length,
        itemBuilder: (context, index) => _InventoryProductCard(
          item: _accumulatedItems[index],
          enabled: widget.canAddItems,
          onTap: () => widget.onSelectProduct(_accumulatedItems[index]),
        ),
        hasMore: catalogState.hasMore,
        isLoading: catalogState.isLoading,
        onLoadMore: () => catalogController.goToPage(catalogState.page + 1),
        emptyMessage: 'Nenhum lote encontrado',
        totalCount: resolvedTotal,
        totalCountLabel: resolvedTotal != null
            ? 'Total: $resolvedTotal lote(s)'
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IgnorePointer(
              ignoring: catalogState.isLoading,
              child: EnterpriseSearchField(
                controller: widget.searchController,
                hintText: 'Pesquisar por nome, substancia activa ou fornecedor...',
                onChanged: catalogController.onSearchChanged,
              ),
            ),
            SizedBox(width: s.sm),
            IconButton(
              onPressed: catalogState.isLoading
                  ? null
                  : catalogController.refreshCurrentPage,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar lista',
            ),
          ],
        ),
        if (catalogState.isLoading) ...[
          SizedBox(height: s.sm),
          const LinearProgressIndicator(),
        ],
        if (catalogState.errorMessage != null) ...[
          SizedBox(height: s.sm),
          _InventoryProductsInlineBanner(
            message: catalogState.errorMessage!,
            icon: Icons.error_outline_rounded,
            color: t.posDanger,
          ),
        ],
        SizedBox(height: s.md),
        Expanded(
          child: !catalogState.isInitialized && catalogState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : catalogState.items.isEmpty
              ? const _InventoryProductsEmptyPane(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nenhum lote encontrado',
                  subtitle:
                      'Ajuste a pesquisa ou actualize a lista para tentar novamente.',
                )
              : EnterpriseDataTable(
                  adaptive: false,
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(label: TableTypography.headerLabel(context, 'PRODUTO')),
                    DataColumn(label: TableTypography.headerLabel(context, 'SUBSTÂNCIA')),
                    DataColumn(label: TableTypography.headerLabel(context, 'DOSAGEM')),
                    DataColumn(label: TableTypography.headerLabel(context, 'FORMA')),
                    DataColumn(label: TableTypography.headerLabel(context, 'APRESENTAÇÃO')),
                    DataColumn(label: TableTypography.headerLabel(context, 'LOTE')),
                    DataColumn(label: TableTypography.headerLabel(context, 'ESTOQUE')),
                    DataColumn(label: TableTypography.headerLabel(context, 'FORNECEDOR')),
                    DataColumn(label: TableTypography.headerLabel(context, 'AÇÕES')),
                  ],
                  rowCount: catalogState.items.length,
                  rowBuilder: (context, index) {
                    final item = catalogState.items[index];
                    return DataRow(
                      onSelectChanged: widget.canAddItems
                          ? (_) => widget.onSelectProduct(item)
                          : null,
                      cells: [
                        DataCell(TableTypography.cellText(context, item.produtoNome, style: TableTypography.primary(context))),
                        DataCell(TableTypography.cellText(context, item.nomeGenerico ?? '—')),
                        DataCell(TableTypography.cellText(context, item.dosagem ?? '—')),
                        DataCell(TableTypography.cellText(context, item.forma ?? '—')),
                        DataCell(TableTypography.cellText(context, item.apresentacao ?? '—')),
                        DataCell(TableTypography.cellText(context, item.numeroLote ?? '—')),
                        DataCell(
                          TableTypography.cellText(
                            context,
                            formatInventoryQuantity(item.estoqueLoteAtual),
                          ),
                        ),
                        DataCell(TableTypography.cellText(context, item.fornecedorNome ?? '—')),
                        DataCell(
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.tonalIcon(
                              onPressed: widget.canAddItems
                                  ? () => widget.onSelectProduct(item)
                                  : null,
                              icon: const Icon(Icons.playlist_add_rounded),
                              label: const Text('Adicionar'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (catalogState.isInitialized &&
            resolvedTotal != null &&
            resolvedTotal > 0) ...[
          EnterprisePagination(
            page: catalogState.page,
            pageSize: catalogState.pageSize,
            totalCount: resolvedTotal,
            itemLabel: 'lotes',
            isBusy: catalogState.isLoading,
            onPageChanged: catalogController.goToPage,
            onPageSizeChanged: catalogController.setPageSize,
          ),
        ],
      ],
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.item,
    required this.enabled,
    required this.onTap,
  });

  final InventarioItem item;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      item.nomeGenerico,
      item.dosagem,
      [
        item.forma,
        item.apresentacao,
      ].whereType<String>().where((value) => value.isNotEmpty).join(' / '),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');

    return EnterpriseListCard(
      leading: Icons.inventory_2_outlined,
      title: item.produtoNome,
      subtitle: details.isNotEmpty ? details : null,
      metadata: [
        EnterpriseListCardMeta(label: 'Lote: ${item.numeroLote ?? '—'}'),
        EnterpriseListCardMeta(
          label: 'Estoque: ${formatInventoryQuantity(item.estoqueLoteAtual)}',
        ),
        if (item.fornecedorNome != null && item.fornecedorNome!.isNotEmpty)
          EnterpriseListCardMeta(label: 'Fornecedor: ${item.fornecedorNome}'),
      ],
      actions: FilledButton.tonalIcon(
        onPressed: enabled ? onTap : null,
        icon: Icon(Icons.playlist_add_rounded, size: DesignMetrics.iconSm),
        label: const Text('Adicionar'),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

class _InventoryProductsInlineBanner extends StatelessWidget {
  const _InventoryProductsInlineBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.erpBody.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryProductsEmptyPane extends StatelessWidget {
  const _InventoryProductsEmptyPane({
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
