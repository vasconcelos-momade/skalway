import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../inputs/enterprise_search_field.dart';

/// Barra de ferramentas mobile com pesquisa, filtros, exportação e atualização.
class EnterpriseMobileToolbar extends StatelessWidget {
  const EnterpriseMobileToolbar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.enabled,
    required this.isLoading,
    required this.hasFilters,
    required this.onSearchSubmitted,
    required this.onOpenFilters,
    required this.onRefresh,
    this.reportAction,
    this.onClearFilters,
    this.filterLabel = 'Filtros',
    this.refreshLabel = 'Atualizar',
    this.exportLabel = 'Exportar..',
    this.showFiltersButton = true,
    this.showRefreshButton = true,
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool enabled;
  final bool isLoading;
  final bool hasFilters;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onOpenFilters;
  final VoidCallback onRefresh;
  final Widget? reportAction;
  final Future<void> Function()? onClearFilters;
  final String filterLabel;
  final String refreshLabel;
  final String exportLabel;
  final bool showFiltersButton;
  final bool showRefreshButton;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final compactButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, DesignMetrics.buttonHeight),
      maximumSize: const Size(double.infinity, DesignMetrics.buttonHeight),
      padding: EdgeInsets.symmetric(horizontal: s.sm),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
    return ColoredBox(
      color: t.bgPrimary,
      child: Container(
        padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.sm),
        decoration: BoxDecoration(
          color: t.bgPrimary,
          border: Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.35))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading) ...[
              const LinearProgressIndicator(minHeight: 2),
              SizedBox(height: s.sm),
            ],
            IgnorePointer(
              ignoring: !enabled,
              child: EnterpriseSearchField(
                controller: searchController,
                hintText: searchHint,
                onChanged: onSearchSubmitted,
              ),
            ),
            SizedBox(height: s.sm),
            Row(
              children: [
                if (showFiltersButton)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: enabled ? onOpenFilters : null,
                      icon: Icon(Icons.tune_rounded, size: t.iconSm),
                      label: Text(
                        hasFilters ? '$filterLabel *' : filterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                if (showFiltersButton && reportAction != null) SizedBox(width: s.sm),
                if (reportAction != null) Expanded(child: reportAction!),
                if (reportAction != null) SizedBox(width: s.sm),
                if (showRefreshButton)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: enabled ? onRefresh : null,
                      icon: Icon(Icons.refresh_rounded, size: t.iconSm),
                      label: Text(
                        refreshLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                if ((showFiltersButton || reportAction != null || showRefreshButton) &&
                    hasFilters &&
                    onClearFilters != null)
                  SizedBox(width: s.sm),
                if (hasFilters && onClearFilters != null)
                  SizedBox(
                    width: DesignMetrics.toolbarHeight,
                    height: DesignMetrics.toolbarHeight,
                    child: IconButton(
                      tooltip: 'Limpar filtros',
                      onPressed: enabled ? () => onClearFilters?.call() : null,
                      icon: Icon(
                        Icons.filter_alt_off_outlined,
                        size: t.iconSm,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de toolbar desktop: pesquisa + filtros inline + acções à direita.
class EnterpriseDesktopListToolbar extends StatefulWidget {
  const EnterpriseDesktopListToolbar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.isLoading,
    required this.onSearchSubmitted,
    required this.filterWidgets,
    this.hasFilters = false,
    this.onClearFilters,
    this.trailingActions = const [],
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool isLoading;
  final ValueChanged<String> onSearchSubmitted;
  final List<Widget> filterWidgets;
  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final List<Widget> trailingActions;

  @override
  State<EnterpriseDesktopListToolbar> createState() => _EnterpriseDesktopListToolbarState();
}

class _EnterpriseDesktopListToolbarState extends State<EnterpriseDesktopListToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseDesktopListToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchChanged);
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: widget.isLoading,
          child: EnterpriseSearchField(
            controller: widget.searchController,
            hintText: widget.searchHint,
            onChanged: widget.onSearchSubmitted,
          ),
        ),
        for (final filter in widget.filterWidgets) ...[
          SizedBox(width: s.md),
          filter,
        ],
        if (widget.hasFilters && widget.onClearFilters != null) ...[
          SizedBox(width: s.sm),
          TextButton.icon(
            onPressed: widget.isLoading ? null : widget.onClearFilters,
            icon: Icon(Icons.filter_alt_off_outlined, size: t.iconSm),
            label: const Text('Limpar'),
          ),
        ],
        const Spacer(),
        if (widget.trailingActions.isNotEmpty) ...[
          SizedBox(width: s.md),
          Align(
            alignment: Alignment.topRight,
            child: Wrap(
              spacing: s.sm,
              runSpacing: s.sm,
              alignment: WrapAlignment.end,
              children: widget.trailingActions,
            ),
          ),
        ],
      ],
    );
  }
}

/// Alias do prompt de design system para toolbars desktop.
typedef EnterpriseDesktopToolbar = EnterpriseDesktopListToolbar;
