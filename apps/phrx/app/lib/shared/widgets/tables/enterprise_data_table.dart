import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';
import '../../responsive/breakpoints.dart' as responsive;
import '../../responsive/pharma_screen_layout.dart';

typedef EnterpriseRowBuilder = DataRow Function(BuildContext context, int index);

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
    return widget.children.map(_describeCellWidget).where((s) => s.trim().isNotEmpty).join(' · ');
  }
  if (widget is Column) {
    return widget.children.map(_describeCellWidget).where((s) => s.trim().isNotEmpty).join(' · ');
  }
  if (widget is Padding) {
    return _describeCellWidget(widget.child);
  }
  if (widget is Center) {
    return _describeCellWidget(widget.child);
  }
  return '';
}

/// Tabela enterprise: em **mobile** lista densa tipo cartão; em tablet/desktop `DataTable`.
class EnterpriseDataTable extends StatelessWidget {
  const EnterpriseDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
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
  });

  final List<DataColumn> columns;
  final int rowCount;
  final EnterpriseRowBuilder rowBuilder;
  final bool adaptive;
  final bool showCheckboxColumn;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<bool?>? onSelectAll;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final double? columnSpacing;
  
  /// Parâmetros de paginação (opcionais, usados para carregar mais dados)
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  Widget _buildTableContent(BuildContext context, BoxConstraints c, PharmaTokens t, DensityTokens s) {
    final viewportWidth = c.maxWidth.isFinite
        ? c.maxWidth
        : responsive.Breakpoints.tablet;

    final tableBody = SizedBox(
      width: viewportWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DataTable(
            showCheckboxColumn: showCheckboxColumn,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            onSelectAll: onSelectAll,
            headingRowColor: WidgetStatePropertyAll(
              t.bgSecondary.withValues(alpha: 0.92),
            ),
            dataRowMinHeight:
                dataRowMinHeight ?? DesignMetrics.tableRowHeightMin,
            dataRowMaxHeight:
                dataRowMaxHeight ?? DesignMetrics.tableRowHeightMax,
            horizontalMargin: PharmaScreenLayout.isDesktop(context)
                ? s.lg
                : s.md,
            columnSpacing: columnSpacing ??
                (PharmaScreenLayout.isDesktop(context) ? s.xxl : s.lg),
            columns: columns,
            rows: List.generate(rowCount, (i) => rowBuilder(context, i)),
          ),
          if (hasMore || isLoading)
            Padding(
              padding: EdgeInsets.all(s.md),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: onLoadMore,
                        child: const Text('Carregar mais'),
                      ),
              ),
            ),
        ],
      ),
    );

    // Scroll horizontal só quando o viewport é estreito para muitas colunas.
    if (viewportWidth < responsive.Breakpoints.tablet && columns.length > 4) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: tableBody,
      );
    }

    return tableBody;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final useCards = adaptive && PharmaScreenLayout.isMobile(context);
        final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;

        if (useCards) {
          Widget listView = ListView.separated(
            shrinkWrap: !boundedHeight,
            physics: boundedHeight
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: rowCount + (hasMore || isLoading ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(height: s.xs),
            itemBuilder: (context, i) {
              if (i == rowCount) {
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
              final row = rowBuilder(context, i);
              final parts = row.cells
                  .map((e) => _describeCellWidget(e.child))
                  .where((part) => part.isNotEmpty)
                  .toList();
              final title = parts.isNotEmpty ? parts.first : '—';
              final rest = parts.length > 1 ? parts.sublist(1).join(' · ') : null;
              return PharmaSurface(
                onTap: row.onSelectChanged != null ? () => row.onSelectChanged!(true) : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.erpTablePrimary.copyWith(
                                height: 1.2,
                                color: t.textPrimary,
                              ),
                            ),
                            if (rest != null && rest.isNotEmpty) ...[
                              SizedBox(height: s.xs),
                              Text(
                                rest,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.erpTableMeta.copyWith(
                                  color: t.textMuted,
                                  height: 1.25,
                                ),
                              ),
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

          if (onRefresh != null && boundedHeight) {
            return RefreshIndicator(
              onRefresh: onRefresh!,
              child: listView,
            );
          }
          return listView;
        }

        Widget tableContent = PharmaSurface(
          clipBehavior: Clip.antiAlias,
          child: _buildTableContent(context, c, t, s),
        );

        if (c.maxWidth.isFinite) {
          tableContent = SizedBox(
            width: c.maxWidth,
            child: tableContent,
          );
        }

        if (boundedHeight) {
          tableContent = SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: tableContent,
          );
        }

        if (onRefresh != null && boundedHeight) {
          return RefreshIndicator(
            onRefresh: onRefresh!,
            child: tableContent,
          );
        }

        return tableContent;
      },
    );
  }
}
