import 'package:flutter/material.dart';

import '../../../core/theme/component_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../inputs/enterprise_search_field.dart';
import '../tables/enterprise_table_filter_panel.dart';

/// Barra de ferramentas mobile com pesquisa, filtros e exportação.
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
    this.onRefresh,
    this.reportAction,
    this.onClearFilters,
    this.filterLabel = 'Filtros',
    this.refreshLabel = 'Atualizar',
    this.exportLabel = 'Exportar..',
    this.showFiltersButton = true,
    this.showRefreshButton = false,
    this.showBottomBorder = true,
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool enabled;
  final bool isLoading;
  final bool hasFilters;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onOpenFilters;
  final VoidCallback? onRefresh;
  final Widget? reportAction;
  final Future<void> Function()? onClearFilters;
  final String filterLabel;
  final String refreshLabel;
  final String exportLabel;
  final bool showFiltersButton;
  final bool showRefreshButton;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final compactButtonStyle = PharmaComponentTheme.outlined(
      t,
      Theme.of(context).colorScheme,
      compact: true,
    );
    return ColoredBox(
      color: t.bgPrimary,
      child: Container(
        // Sem padding horizontal — o shell já aplica s.md em mobile.
        padding: EdgeInsets.symmetric(vertical: s.sm),
        decoration: BoxDecoration(
          color: t.bgPrimary,
          border: showBottomBorder
              ? Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.35)))
              : null,
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
                      onPressed: enabled && onRefresh != null ? onRefresh : null,
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
                    width: t.controlHeight,
                    height: t.controlHeight,
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

/// Linha de toolbar desktop: pesquisa + [Filtros ▾] + acções à direita.
///
/// Filtros abrem [EnterpriseTableFilterPanel] (dropdown) em vez de selects
/// inline — padrão enterprise (Fluent / Carbon / Ant Design).
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
    this.onApplyFilters,
    this.onOpenFilters,
    this.filterTitle = 'Filtros',
    this.trailingActions = const [],
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool isLoading;
  final ValueChanged<String> onSearchSubmitted;

  /// Campos do painel de filtros (não renderizados inline).
  final List<Widget> filterWidgets;
  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onApplyFilters;
  final VoidCallback? onOpenFilters;
  final String filterTitle;
  final List<Widget> trailingActions;

  @override
  State<EnterpriseDesktopListToolbar> createState() =>
      _EnterpriseDesktopListToolbarState();
}

class _EnterpriseDesktopListToolbarState
    extends State<EnterpriseDesktopListToolbar> {
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

  void _openFilters(BuildContext buttonContext) {
    if (widget.onOpenFilters != null) {
      widget.onOpenFilters!();
      return;
    }
    if (widget.filterWidgets.isEmpty) return;

    EnterpriseTableFilterPanel.present(
      context: context,
      anchorContext: buttonContext,
      filters: widget.filterWidgets,
      title: widget.filterTitle,
      onClear: widget.onClearFilters,
      onApply: widget.onApplyFilters ?? () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final hasFilterTrigger =
        widget.filterWidgets.isNotEmpty || widget.onOpenFilters != null;
    final hasTrailing = widget.trailingActions.isNotEmpty;
    final compactStyle = PharmaComponentTheme.outlined(
      t,
      scheme,
      compact: true,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IgnorePointer(
              ignoring: widget.isLoading,
              child: EnterpriseSearchField(
                controller: widget.searchController,
                hintText: widget.searchHint,
                onChanged: widget.onSearchSubmitted,
              ),
            ),
          ),
        ),
        if (hasFilterTrigger || hasTrailing) ...[
          SizedBox(width: s.md),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: s.sm,
                runSpacing: s.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  if (hasFilterTrigger)
                    Builder(
                      builder: (buttonContext) {
                        final label =
                            widget.hasFilters ? 'Filtros *' : 'Filtros';
                        return OutlinedButton.icon(
                          style: compactStyle,
                          onPressed: widget.isLoading
                              ? null
                              : () => _openFilters(buttonContext),
                          icon: Icon(
                            Icons.filter_list_rounded,
                            size: t.iconSm,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label),
                              SizedBox(width: s.xxs),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: t.iconSm,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ...widget.trailingActions,
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Alias do prompt de design system para toolbars desktop.
typedef EnterpriseDesktopToolbar = EnterpriseDesktopListToolbar;
