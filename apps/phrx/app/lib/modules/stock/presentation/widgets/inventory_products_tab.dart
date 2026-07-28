import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/categories/domain/entities/category.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventory_catalog_provider.dart';
import 'inventory_count_sheet.dart';

/// Tabela principal de produtos aptos para inventário.
class InventoryProductsTab extends ConsumerStatefulWidget {
  const InventoryProductsTab({
    super.key,
    required this.searchController,
    required this.canInventariar,
    required this.categories,
    required this.onInventariar,
  });

  final TextEditingController searchController;
  final bool canInventariar;
  final List<Category> categories;
  final ValueChanged<InventarioProdutoApto> onInventariar;

  @override
  ConsumerState<InventoryProductsTab> createState() =>
      _InventoryProductsTabState();
}

class _InventoryProductsTabState extends ConsumerState<InventoryProductsTab> {
  List<InventarioProdutoApto> _accumulatedItems = [];

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(inventoryCatalogProvider);
    final catalogController = ref.read(inventoryCatalogProvider.notifier);
    final t = context.pharmaTokens;
    final s = t.density;
    final isMobile = MediaQuery.sizeOf(context).width <= 920;
    final resolvedTotal = catalogState.resolvedTotalCount;

    ref.listen<InventoryCatalogState>(inventoryCatalogProvider, (prev, next) {
      if (!mounted) return;

      if (prev?.query != next.query ||
          prev?.categoriaId != next.categoriaId ||
          prev?.estadoSanitario != next.estadoSanitario ||
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

    if (!catalogState.isInitialized && catalogState.isLoading) {
      return const ModuleLoadingState();
    }

    if (catalogState.errorMessage != null && catalogState.items.isEmpty) {
      return ModuleErrorState(
        title: 'Erro ao carregar produtos',
        message: catalogState.errorMessage!,
        onRetry: catalogController.refreshCurrentPage,
      );
    }

    if (isMobile) {
      return EnterpriseMobileScrollList(
        errorText: catalogState.errorMessage,
        stickyHeader: EnterpriseMobileToolbar(
          searchController: widget.searchController,
          searchHint: 'Nome comercial ou código de barras...',
          enabled: !catalogState.isLoading,
          isLoading: catalogState.isLoading,
          hasFilters: catalogState.hasFilters,
          onSearchSubmitted: catalogController.onSearchChanged,
          onOpenFilters: () {},
          showFiltersButton: false,
          onClearFilters: catalogController.clearFilters,
        ),
        itemCount: _accumulatedItems.length,
        isLoading: catalogState.isLoading,
        hasMore: catalogState.hasMore,
        onLoadMore: () => catalogController.goToPage(catalogState.page + 1),
        emptyMessage:
            'Não existem produtos activos com lotes válidos para inventário.',
        itemBuilder: (context, index) {
          final item = _accumulatedItems[index];
          return EnterpriseListCard(
            title: item.nomeComercial,
            subtitle:
                '${item.dosagem ?? '—'} · ${item.forma ?? '—'} · ${formatInventoryQuantity(item.stockAtual)} un · ${item.lotesCount} lotes',
            chip: EnterpriseStatusChip(
              label: 'Válido',
              color: t.posSuccess,
            ),
            trailing: IconButton(
              tooltip: 'Inventariar',
              onPressed: widget.canInventariar
                  ? () => widget.onInventariar(item)
                  : null,
              icon: Icon(
                Icons.edit_note_outlined,
                color: widget.canInventariar ? t.brandGreen : t.textMuted,
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnterpriseDesktopListToolbar(
          searchController: widget.searchController,
          searchHint: 'Pesquisar nome comercial ou código de barras...',
          isLoading: catalogState.isLoading,
          onSearchSubmitted: catalogController.onSearchChanged,
          hasFilters: catalogState.hasFilters,
          onClearFilters:
              catalogState.isLoading ? null : catalogController.clearFilters,
          filterWidgets: [
            SizedBox(
              width: 170,
              child: EnterpriseSelectField<String>(
                key: ValueKey('inv-cat-${catalogState.categoriaId}'),
                label: 'Categoria',
                emptyLabel: 'Todas',
                value: catalogState.categoriaId,
                options: [
                  for (final c in widget.categories)
                    EnterpriseSelectOption<String>(value: c.id, label: c.nome),
                ],
                onChanged: catalogState.isLoading
                    ? null
                    : catalogController.setCategoriaFilter,
              ),
            ),
            SizedBox(
              width: 160,
              child: EnterpriseSelectField<String>(
                key: ValueKey('inv-est-${catalogState.estadoSanitario}'),
                label: 'Estado Sanitário',
                emptyLabel: 'Válido',
                value: catalogState.estadoSanitario,
                options: const [
                  EnterpriseSelectOption<String>(
                    value: 'VALIDO',
                    label: 'Válido',
                  ),
                  EnterpriseSelectOption<String>(
                    value: 'EXPIRADO',
                    label: 'Expirado',
                  ),
                  EnterpriseSelectOption<String>(
                    value: 'RECALL',
                    label: 'Recall',
                  ),
                  EnterpriseSelectOption<String>(
                    value: 'QUARENTENA',
                    label: 'Quarentena',
                  ),
                ],
                onChanged: catalogState.isLoading
                    ? null
                    : catalogController.setEstadoSanitarioFilter,
              ),
            ),
          ],
        ),
        SizedBox(height: s.md),
        Expanded(
          child: catalogState.items.isEmpty
              ? const ModuleEmptyState(
                  title: 'Sem produtos aptos',
                  subtitle:
                      'Não existem produtos activos com lotes válidos para inventário.',
                )
              : EnterpriseDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Produto')),
                    DataColumn(label: Text('Dosagem')),
                    DataColumn(label: Text('Forma')),
                    DataColumn(label: Text('Estado Sanitário')),
                    DataColumn(label: Text('Stock Atual')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rowCount: catalogState.items.length,
                  rowBuilder: (context, index) {
                    final item = catalogState.items[index];
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.nomeComercial,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        DataCell(Text(item.dosagem?.trim().isNotEmpty == true
                            ? item.dosagem!
                            : '—')),
                        DataCell(Text(item.forma?.trim().isNotEmpty == true
                            ? item.forma!
                            : '—')),
                        DataCell(
                          EnterpriseStatusChip(
                            label: 'Válido',
                            color: t.posSuccess,
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${formatInventoryQuantity(item.stockAtual)} unidades',
                              ),
                              Text(
                                '${item.lotesCount} lotes',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: t.textMuted),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'Inventariar',
                            onPressed: widget.canInventariar
                                ? () => widget.onInventariar(item)
                                : null,
                            icon: Icon(
                              Icons.edit_note_outlined,
                              size: t.iconMd,
                              color: widget.canInventariar
                                  ? t.brandGreen
                                  : t.textMuted,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (resolvedTotal != null) ...[
          SizedBox(height: s.sm),
          EnterprisePagination(
            page: catalogState.page,
            pageSize: catalogState.pageSize,
            totalCount: resolvedTotal,
            isBusy: catalogState.isLoading,
            itemLabel: 'produtos',
            onPageChanged: catalogController.goToPage,
            onPageSizeChanged: catalogController.setPageSize,
          ),
        ],
      ],
    );
  }
}
