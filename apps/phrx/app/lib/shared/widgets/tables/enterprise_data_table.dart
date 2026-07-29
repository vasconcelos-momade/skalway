import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../feedback/module_data_states.dart';
import 'enterprise_table_body.dart';
import 'enterprise_table_cells.dart';
import 'enterprise_table_column.dart';
import 'enterprise_table_header.dart';
import 'enterprise_table_toolbar.dart';

typedef EnterpriseRowBuilder = DataRow Function(BuildContext context, int index);

/// Estado visual da tabela — chrome (toolbar/header/pagination) permanece visível.
enum EnterpriseTableStatus {
  loading,
  empty,
  error,
  data,
}

String _describeCellWidget(Widget? widget) {
  if (widget == null) return '';
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }
  if (widget is Chip) {
    return _describeCellWidget(widget.label);
  }
  if (widget is Icon || widget is IconButton) return '';
  if (widget is Row) {
    return widget.children
        .map(_describeCellWidget)
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
  }
  if (widget is Column) {
    return widget.children
        .map(_describeCellWidget)
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
  }
  if (widget is Padding) {
    return _describeCellWidget(widget.child);
  }
  if (widget is Center) {
    return _describeCellWidget(widget.child);
  }
  if (widget is Align) {
    return _describeCellWidget(widget.child);
  }
  return '';
}

/// Tabela enterprise reutilizável (Fluent / Carbon / Ant Design patterns).
///
/// Estrutura (sempre visível, inclusive empty/loading/error):
/// ```
/// ┌─────────────────────────────┐
/// │ EnterpriseTableToolbar FIXA │
/// ├─────────────────────────────┤
/// │ TableHeader FIXO (sticky)   │
/// ├─────────────────────────────┤
/// │ TableBody / EmptyState      │
/// ├─────────────────────────────┤
/// │ Pagination FIXA             │
/// └─────────────────────────────┘
/// ```
class EnterpriseDataTable<T> extends StatelessWidget {
  const EnterpriseDataTable({
    super.key,
    this.columns,
    this.enterpriseColumns,
    this.items,
    this.rowCount,
    this.rowBuilder,
    this.adaptive = true,
    this.showCheckboxColumn = true,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.columnSpacing,
    this.hasMore = false,
    this.isLoading = false,
    this.onLoadMore,
    this.onRefresh,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.toolbarActions,
    this.filters,
    this.filterWidgets,
    this.filterTitle = 'Filtros',
    this.hasActiveFilters = false,
    this.onClearFilters,
    this.onApplyFilters,
    this.onOpenFilters,
    this.pagination,
    this.emptyMessage = 'Nenhum registo encontrado',
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyPrimaryActionLabel,
    this.onEmptyPrimaryAction,
    this.errorTitle = 'Falha ao carregar',
    this.errorMessage,
    this.onRetry,
    this.status,
    this.zebraStripes,
  }) : assert(
          enterpriseColumns != null || columns != null,
          'Informe enterpriseColumns ou columns',
        ),
        assert(
          enterpriseColumns == null || items != null || rowBuilder != null,
          'Com enterpriseColumns informe items ou rowBuilder',
        ),
        assert(
          columns == null || rowBuilder != null,
          'Com columns informe rowBuilder',
        );

  final List<DataColumn>? columns;
  final List<EnterpriseTableColumn<T>>? enterpriseColumns;
  final List<T>? items;
  final int? rowCount;
  final EnterpriseRowBuilder? rowBuilder;
  final bool adaptive;
  final bool showCheckboxColumn;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<bool?>? onSelectAll;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final double? columnSpacing;

  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? toolbarActions;
  final List<Widget>? filters;
  final List<Widget>? filterWidgets;
  final String filterTitle;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onApplyFilters;
  final VoidCallback? onOpenFilters;
  final Widget? pagination;

  final String emptyMessage;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? emptyPrimaryActionLabel;
  final VoidCallback? onEmptyPrimaryAction;

  final String errorTitle;
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// Se nulo, deriva de [isLoading] / [rowCount].
  final EnterpriseTableStatus? status;

  final bool? zebraStripes;

  int get _resolvedRowCount {
    if (rowCount != null) return rowCount!;
    if (items != null) return items!.length;
    return 0;
  }

  EnterpriseTableStatus get _resolvedStatus {
    if (status != null) return status!;
    if (isLoading && _resolvedRowCount == 0) return EnterpriseTableStatus.loading;
    if (errorMessage != null && _resolvedRowCount == 0) {
      return EnterpriseTableStatus.error;
    }
    if (_resolvedRowCount == 0) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  Widget _buildToolbar(BuildContext context) {
    return EnterpriseTableToolbar(
      searchHint: searchHint,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      toolbarActions: toolbarActions,
      filters: filters,
      filterWidgets: filterWidgets,
      filterTitle: filterTitle,
      hasActiveFilters: hasActiveFilters,
      onClearFilters: onClearFilters,
      onApplyFilters: onApplyFilters,
      onOpenFilters: onOpenFilters,
      enabled: !isLoading,
    );
  }

  Widget _buildBodyOverlay(BuildContext context) {
    final resolved = _resolvedStatus;
    return switch (resolved) {
      EnterpriseTableStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      EnterpriseTableStatus.error => ModuleErrorState(
          title: errorTitle,
          message: errorMessage ?? 'Erro desconhecido',
          onRetry: onRetry ?? () {},
        ),
      EnterpriseTableStatus.empty => ModuleEmptyState(
          title: emptyTitle ?? emptyMessage,
          subtitle: emptySubtitle,
          onClearFilters: hasActiveFilters ? onClearFilters : null,
          primaryActionLabel: emptyPrimaryActionLabel,
          onPrimaryAction: onEmptyPrimaryAction,
        ),
      EnterpriseTableStatus.data => const SizedBox.shrink(),
    };
  }

  Widget _buildDesktopTable(BuildContext context, BoxConstraints c) {
    final s = context.spacing;
    final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;
    final count = _resolvedRowCount;
    final resolvedStatus = _resolvedStatus;
    final showRows = resolvedStatus == EnterpriseTableStatus.data;

    final List<DataColumn> resolvedColumns;
    if (enterpriseColumns != null) {
      resolvedColumns =
          EnterpriseTableColumn.toDataColumns(context, enterpriseColumns!);
    } else {
      resolvedColumns = columns!;
    }

    final List<DataRow> rows;
    if (!showRows) {
      rows = const [];
    } else if (enterpriseColumns != null && items != null && rowBuilder == null) {
      rows = EnterpriseTableColumn.buildRows<T>(
        context: context,
        items: items!,
        columns: enterpriseColumns!,
      );
    } else {
      rows = List.generate(count, (i) => rowBuilder!(context, i));
    }

    final header = EnterpriseTableHeader(
      columns: resolvedColumns,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSelectAll: onSelectAll,
    );

    final dataTable = EnterpriseTableBody(
      header: header,
      rows: rows,
      showCheckboxColumn: showCheckboxColumn,
      dataRowMinHeight: dataRowMinHeight,
      dataRowMaxHeight: dataRowMaxHeight,
      columnSpacing: columnSpacing,
      emptyMessage: emptyMessage,
      zebraStripes: zebraStripes ?? true,
      emptyPlaceholder: showRows ? null : _buildBodyOverlay(context),
    );

    final loadMore = showRows && (hasMore || isLoading)
        ? Padding(
            padding: EdgeInsets.all(s.md),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text('Carregar mais'),
                    ),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context),
        if (boundedHeight)
          Expanded(child: dataTable)
        else
          SizedBox(
            height: (showRows ? count : 4) *
                    (dataRowMaxHeight ?? DesignMetrics.tableRowHeightMax) +
                DesignMetrics.tableRowHeightMin +
                s.lg,
            child: dataTable,
          ),
        ?loadMore,
      ],
    );
  }

  Widget _buildMobileCards(BuildContext context, BoxConstraints c) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;
    final count = _resolvedRowCount;
    final resolvedStatus = _resolvedStatus;

    Widget body;
    if (resolvedStatus != EnterpriseTableStatus.data) {
      body = _buildBodyOverlay(context);
    } else {
      body = ListView.separated(
        shrinkWrap: !boundedHeight,
        physics: boundedHeight
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: count + (hasMore || isLoading ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: s.xs),
        itemBuilder: (context, i) {
          if (i == count) {
            return Padding(
              padding: EdgeInsets.all(s.md),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: onLoadMore,
                        child: const Text('Carregar mais'),
                      ),
              ),
            );
          }

          final DataRow row;
          if (enterpriseColumns != null && items != null && rowBuilder == null) {
            final built = EnterpriseTableColumn.buildRows<T>(
              context: context,
              items: [items![i]],
              columns: enterpriseColumns!,
            );
            row = built.first;
          } else {
            row = rowBuilder!(context, i);
          }

          final parts = row.cells
              .map((e) => _describeCellWidget(e.child))
              .where((part) => part.isNotEmpty)
              .toList();
          final title = parts.isNotEmpty ? parts.first : '—';
          final rest = parts.length > 1 ? parts.sublist(1).join(' · ') : null;

          return PharmaSurface(
            onTap: row.onSelectChanged != null
                ? () => row.onSelectChanged!(true)
                : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TablePrimaryCell(
                          title,
                          maxLines: 2,
                        ),
                        if (rest != null && rest.isNotEmpty) ...[
                          SizedBox(height: s.xs),
                          TableMetadataCell(rest, maxLines: 3),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: t.iconSm,
                    color: t.textMuted,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context),
        if (boundedHeight)
          Expanded(child: body)
        else
          body,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final useCards = adaptive && PharmaScreenLayout.isMobile(context);
        final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;

        Widget content = useCards
            ? _buildMobileCards(context, c)
            : PharmaSurface(
                clipBehavior: Clip.antiAlias,
                child: _buildDesktopTable(context, c),
              );

        if (!useCards && c.maxWidth.isFinite) {
          content = SizedBox(width: c.maxWidth, child: content);
        }

        if (pagination != null) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (boundedHeight) Expanded(child: content) else content,
              pagination!,
            ],
          );
        }

        if (onRefresh != null && boundedHeight) {
          return RefreshIndicator(
            onRefresh: onRefresh!,
            child: content,
          );
        }

        return content;
      },
    );
  }
}
