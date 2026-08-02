import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventario_provider.dart';
import '../providers/inventory_catalog_provider.dart';
import 'inventory_count_sheet.dart';

/// Largura do painel de Itens Inventariados — ligeiramente superior ao form sheet
/// canónico para acomodar a tabela sem dominar o ecrã.
double _inventariadosSheetWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (screenWidth >= DesignMetrics.overlayDesktopBreakpoint) {
    return 780;
  }
  return 640;
}

Future<void> showInventariadosSheet(BuildContext context) {
  return AdaptiveNavigator.openPanel<void>(
    context: context,
    routeSettings: const RouteSettings(name: '/inventario/itens'),
    sideSheetWidth: _inventariadosSheetWidth(context),
    builder: (sheetContext) {
      if (AdaptiveNavigator.isMobile(sheetContext)) {
        return Scaffold(
          appBar: AppBar(title: const Text('Itens Inventariados')),
          body: const SafeArea(child: _InventariadosBody()),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseOverlayHeader(
            title: const Text('Itens Inventariados'),
            onClose: () => AdaptiveNavigator.close(sheetContext),
          ),
          Divider(
            height: BorderTokens.width,
            color: sheetContext.pharmaTokens.borderSubtle,
          ),
          const Expanded(child: _InventariadosBody()),
        ],
      );
    },
  );
}

class _InventariadosBody extends ConsumerStatefulWidget {
  const _InventariadosBody();

  @override
  ConsumerState<_InventariadosBody> createState() => _InventariadosBodyState();
}

class _InventariadosBodyState extends ConsumerState<_InventariadosBody> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _sortBy = 'produto';
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _finalizar(BuildContext context) async {
    final state = ref.read(inventarioProvider);
    if (!state.canReconcile) return;

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Finalizar Inventário',
      message:
          'Serão gerados movimentos AJUSTE para cada divergência e o inventário será marcado como concluído. Continuar?',
      confirmText: 'Finalizar',
      cancelText: 'Cancelar',
    );
    if (confirmed != true) return;

    await ref.read(inventarioProvider.notifier).reconcileActiveInventory();
    await ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage();
    if (!context.mounted) return;
    AdaptiveNavigator.close(context);
  }

  Future<void> _editItem(InventarioItem item) async {
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => _EditCountDialog(item: item),
    );
    if (value == null) return;
    await ref.read(inventarioProvider.notifier).recordCount(
          item: item,
          estoqueContado: value,
        );
  }

  Future<void> _removeItem(InventarioItem item) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Remover item',
      message:
          'Remover o lote ${item.numeroLote ?? item.produtoNome} do inventário?',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      destructive: true,
    );
    if (confirmed != true) return;
    await ref.read(inventarioProvider.notifier).removeItem(item);
    if (!mounted) return;
    setState(() {
      final remaining =
          _filteredSorted(ref.read(inventarioProvider).inventariadosItems);
      final maxPage = remaining.isEmpty
          ? 1
          : ((remaining.length - 1) / _pageSize).floor() + 1;
      if (_page > maxPage) _page = maxPage;
    });
  }

  String? _productSubtitle(InventarioItem item) {
    final generico = item.nomeGenerico?.trim();
    if (generico != null && generico.isNotEmpty) return generico;
    final parts = <String>[
      if (item.dosagem?.trim().isNotEmpty == true) item.dosagem!.trim(),
      if (item.forma?.trim().isNotEmpty == true) item.forma!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  List<InventarioItem> _filteredSorted(List<InventarioItem> source) {
    final query = _searchQuery.trim().toLowerCase();
    var items = source;
    if (query.isNotEmpty) {
      items = items.where((item) {
        final haystack = [
          item.produtoNome,
          item.nomeGenerico,
          item.dosagem,
          item.forma,
          item.apresentacao,
          item.numeroLote,
          item.fornecedorNome,
        ]
            .whereType<String>()
            .map((e) => e.toLowerCase())
            .join(' ');
        return haystack.contains(query);
      }).toList();
    }

    int compare(InventarioItem a, InventarioItem b) {
      final result = switch (_sortBy) {
        'lote' => (a.numeroLote ?? '').compareTo(b.numeroLote ?? ''),
        'validade' => (a.dataValidade ?? '').compareTo(b.dataValidade ?? ''),
        'sistema' => a.estoqueSistema.compareTo(b.estoqueSistema),
        'contado' => a.estoqueContado.compareTo(b.estoqueContado),
        'diferenca' => a.divergencia.compareTo(b.divergencia),
        'estado' => a.hasDivergencia == b.hasDivergencia
            ? 0
            : (a.hasDivergencia ? 1 : -1),
        _ => a.produtoNome.toLowerCase().compareTo(b.produtoNome.toLowerCase()),
      };
      return _sortAscending ? result : -result;
    }

    final sorted = List<InventarioItem>.of(items)..sort(compare);
    return sorted;
  }

  List<InventarioItem> _pageItems(List<InventarioItem> filtered) {
    final start = (_page - 1) * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _page = 1;
    });
  }

  void _handleSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
      _page = 1;
    });
  }

  int? get _sortColumnIndex => switch (_sortBy) {
        'produto' => 0,
        'lote' => 1,
        'validade' => 2,
        'sistema' => 3,
        'contado' => 4,
        'diferenca' => 5,
        'estado' => 6,
        _ => null,
      };

  String _formatValidade(InventarioItem item) {
    if (item.dataValidade == null) return '—';
    final date = DateTime.tryParse(item.dataValidade!);
    return date == null ? item.dataValidade! : formatInventoryDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final state = ref.watch(inventarioProvider);
    final allItems = state.inventariadosItems;
    final filtered = _filteredSorted(allItems);
    final pageItems = _pageItems(filtered);
    final isMobile = PharmaScreenLayout.isMobile(context);
    final isLoading = state.isLoadingActive && allItems.isEmpty;
    final hasSearch = _searchQuery.trim().isNotEmpty;

    final EnterpriseTableStatus tableStatus;
    if (isLoading) {
      tableStatus = EnterpriseTableStatus.loading;
    } else if (allItems.isEmpty) {
      tableStatus = EnterpriseTableStatus.empty;
    } else if (filtered.isEmpty) {
      tableStatus = EnterpriseTableStatus.empty;
    } else {
      tableStatus = EnterpriseTableStatus.data;
    }

    Widget list;
    if (isMobile) {
      // Mesma margem horizontal para pesquisa e cards (alinhamento enterprise).
      final horizontalInset = s.md;

      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              s.md,
              horizontalInset,
              s.sm,
            ),
            child: TextField(
              controller: _searchController,
              enabled: !state.isBusy,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar produto, lote ou substância...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Limpar',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(s.lg),
                      child: Text(
                        allItems.isEmpty
                            ? 'Ainda não há itens inventariados.'
                            : 'Nenhum item corresponde à pesquisa.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      horizontalInset,
                      0,
                      horizontalInset,
                      s.md,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) => Padding(
                      padding: EdgeInsets.symmetric(vertical: s.md),
                      child: Divider(
                        height: BorderTokens.width,
                        thickness: BorderTokens.width,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _InventoryMobileCard(
                        item: item,
                        isBusy: state.isBusy,
                        onEdit: () => _editItem(item),
                        onRemove: () => _removeItem(item),
                      );
                    },
                  ),
          ),
        ],
      );
    } else {
      list = Padding(
        padding: EdgeInsets.only(left: s.md, right: s.md, bottom: s.sm),
        child: EnterpriseDataTable(
          adaptive: false,
          showCheckboxColumn: false,
          status: tableStatus,
          isLoading: isLoading,
          searchController: _searchController,
          searchHint: 'Pesquisar produto, lote ou substância...',
          onSearchChanged: _onSearchChanged,
          hasActiveFilters: hasSearch,
          onClearFilters: hasSearch
              ? () {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              : null,
          emptyTitle: allItems.isEmpty
              ? 'Ainda não há itens inventariados.'
              : 'Nenhum item encontrado',
          emptySubtitle: allItems.isEmpty
              ? 'Inventarie lotes a partir da lista de produtos aptos.'
              : 'Ajuste a pesquisa para ver resultados.',
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          columnSpacing: s.xl,
          zebraStripes: true,
          pagination: filtered.isEmpty
              ? null
              : EnterprisePagination(
                  page: _page,
                  pageSize: _pageSize,
                  totalCount: filtered.length,
                  itemsOnPage: pageItems.length,
                  isBusy: state.isBusy,
                  itemLabel: 'itens',
                  onPageChanged: (page) => setState(() => _page = page),
                  onPageSizeChanged: (size) => setState(() {
                    _pageSize = size;
                    _page = 1;
                  }),
                ),
          columns: [
            enterpriseDataColumn(
              context,
              'Produto',
              onSort: (_, _) => _handleSort('produto'),
            ),
            enterpriseDataColumn(
              context,
              'Lote',
              onSort: (_, _) => _handleSort('lote'),
            ),
            enterpriseDataColumn(
              context,
              'Validade',
              onSort: (_, _) => _handleSort('validade'),
            ),
            enterpriseDataColumn(
              context,
              'Stock Sistema',
              numeric: true,
              onSort: (_, _) => _handleSort('sistema'),
            ),
            enterpriseDataColumn(
              context,
              'Qtd Contada',
              numeric: true,
              onSort: (_, _) => _handleSort('contado'),
            ),
            enterpriseDataColumn(
              context,
              'Diferença',
              numeric: true,
              onSort: (_, _) => _handleSort('diferenca'),
            ),
            enterpriseDataColumn(
              context,
              'Estado',
              onSort: (_, _) => _handleSort('estado'),
            ),
            enterpriseDataColumn(context, 'Ações'),
          ],
          rowCount: pageItems.length,
          rowBuilder: (context, index) {
            final item = pageItems[index];
            final diffColor = item.divergencia == 0
                ? null
                : (item.divergencia > 0 ? t.posSuccess : t.posDanger);

            return DataRow(
              cells: [
                DataCell(
                  TablePrimaryCell(
                    item.produtoNome,
                    subtitle: _productSubtitle(item),
                  ),
                ),
                DataCell(TablePrimaryCell(item.numeroLote ?? '—')),
                DataCell(TablePrimaryCell(_formatValidade(item))),
                DataCell(
                  TableNumericCell(
                    formatInventoryQuantity(item.estoqueSistema),
                  ),
                ),
                DataCell(
                  TableNumericCell(
                    formatInventoryQuantity(item.estoqueContado),
                  ),
                ),
                DataCell(
                  TableNumericCell(
                    formatInventoryQuantity(item.divergencia),
                    color: diffColor,
                  ),
                ),
                DataCell(
                  EnterpriseStatusChip(
                    label: item.hasDivergencia ? 'Divergência' : 'OK',
                    color: item.hasDivergencia ? t.posWarning : t.posSuccess,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed:
                            state.isBusy ? null : () => _editItem(item),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: t.iconSm,
                          color: t.textPrimary,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed:
                            state.isBusy ? null : () => _removeItem(item),
                        icon: Icon(
                          Icons.delete_outline,
                          size: t.iconSm,
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: list),
        EnterpriseOverlayFooter(
          expandOnNarrow: isMobile,
          actions: [
            EnterpriseOverlayActions.secondary(
              label: 'Fechar',
              onPressed: () => AdaptiveNavigator.close(context),
            ),
            if (state.canReconcile)
              FilledButton.icon(
                onPressed:
                    state.isReconciling ? null : () => _finalizar(context),
                icon: state.isReconciling
                    ? const PharmaButtonLoader()
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Finalizar Inventário'),
              ),
          ],
        ),
      ],
    );
  }
}

class _InventoryMobileCard extends StatelessWidget {
  const _InventoryMobileCard({
    required this.item,
    required this.isBusy,
    required this.onEdit,
    required this.onRemove,
  });

  final InventarioItem item;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  static ButtonStyle get _actionButtonStyle => IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final diffColor = item.divergencia == 0
        ? null
        : (item.divergencia > 0 ? t.posSuccess : t.posDanger);

    // Sem padding horizontal extra — a lista já aplica a mesma margem da pesquisa.
    // Espaçamento vertical entre itens fica no separador (12px acima/abaixo da linha).
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produtoNome,
                      style: theme.textTheme.erpCardTitle.copyWith(
                        color: t.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: s.xxs),
                    Text(
                      'Lote: ${item.numeroLote ?? '—'}',
                      style: theme.textTheme.erpBodySecondary.copyWith(
                        color: t.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: s.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EnterpriseStatusChip(
                    label: item.hasDivergencia ? 'Divergência' : 'OK',
                    color: item.hasDivergencia ? t.posWarning : t.posSuccess,
                  ),
                  SizedBox(width: s.xs),
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: isBusy ? null : onEdit,
                    style: _actionButtonStyle,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: t.iconSm,
                      color: t.textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover',
                    onPressed: isBusy ? null : onRemove,
                    style: _actionButtonStyle,
                    icon: Icon(
                      Icons.delete_outline,
                      size: t.iconSm,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: _StatInline(
                  label: 'Stock Sist.',
                  value: formatInventoryQuantity(item.estoqueSistema),
                  align: TextAlign.start,
                ),
              ),
              Expanded(
                child: _StatInline(
                  label: 'Contada',
                  value: formatInventoryQuantity(item.estoqueContado),
                  align: TextAlign.center,
                ),
              ),
              Expanded(
                child: _StatInline(
                  label: 'Diferença',
                  value: formatInventoryQuantity(item.divergencia),
                  valueColor: diffColor,
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatInline extends StatelessWidget {
  const _StatInline({
    required this.label,
    required this.value,
    this.valueColor,
    this.align = TextAlign.center,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.erpBodySecondary.copyWith(
          color: t.textSecondary,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: theme.textTheme.erpBody.copyWith(
              color: valueColor ?? t.textPrimary,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
    );
  }
}

class _EditCountDialog extends StatefulWidget {
  const _EditCountDialog({required this.item});

  final InventarioItem item;

  @override
  State<_EditCountDialog> createState() => _EditCountDialogState();
}

class _EditCountDialogState extends State<_EditCountDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatInventoryQuantity(widget.item.estoqueContado),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PharmaResponsiveDialog(
      title: const Text('Editar contagem'),
      content: EnterpriseTextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        labelText: 'Unidades Contadas',
        helperText:
            'Stock sistema: ${formatInventoryQuantity(widget.item.estoqueSistema)}',
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () {
                  final value = double.tryParse(
                    _controller.text.replaceAll(',', '.'),
                  );
                  if (value == null) return;
                  setState(() => _saving = true);
                  Navigator.pop(context, value);
                },
          child: _saving
              ? const PharmaButtonLoader()
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
