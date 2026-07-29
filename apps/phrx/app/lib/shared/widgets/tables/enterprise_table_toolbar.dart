import 'package:flutter/material.dart';

import '../../../core/theme/component_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../inputs/enterprise_search_field.dart';
import 'enterprise_table_filter_panel.dart';

/// Toolbar fixa da tabela enterprise.
///
/// Layout Desktop:
/// ```
/// [ 🔍 Pesquisar... ]                 [Filtros ▾] [Novo] ...
/// ```
///
/// Filtros abrem [EnterpriseTableFilterPanel] (dropdown desktop / side sheet
/// em ecrãs menores). Não colocar múltiplos filtros inline na toolbar.
class EnterpriseTableToolbar extends StatelessWidget {
  const EnterpriseTableToolbar({
    super.key,
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
    this.enabled = true,
  });

  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  /// Acções da tabela (Novo, Exportar, etc.).
  final List<Widget>? toolbarActions;

  /// Campos do painel de filtros (abordagem enterprise).
  final List<Widget>? filters;

  /// Legado: filtros inline — agora abertos via botão Filtros no painel.
  final List<Widget>? filterWidgets;

  final String filterTitle;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onApplyFilters;

  /// Override: o caller controla a abertura do painel.
  final VoidCallback? onOpenFilters;

  final bool enabled;

  List<Widget> get _resolvedFilters {
    if (filters != null && filters!.isNotEmpty) return filters!;
    if (filterWidgets != null && filterWidgets!.isNotEmpty) {
      return filterWidgets!;
    }
    return const [];
  }

  bool get _hasFilterTrigger =>
      _resolvedFilters.isNotEmpty || onOpenFilters != null;

  bool get _hasSearch => searchController != null;

  bool get _hasActions =>
      toolbarActions != null && toolbarActions!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasSearch && !_hasFilterTrigger && !_hasActions) {
      return const SizedBox.shrink();
    }

    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final isTablet = PharmaScreenLayout.isTablet(context);
    final padding = EdgeInsets.all(isMobile || isTablet ? s.sm : s.md);

    if (isMobile) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasSearch) _buildSearch(context),
            if (_hasSearch && (_hasFilterTrigger || _hasActions))
              SizedBox(height: s.sm),
            if (_hasFilterTrigger || _hasActions)
              _buildMobileActionsRow(context),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_hasSearch)
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildSearch(context),
              ),
            ),
          if (_hasSearch && (_hasFilterTrigger || _hasActions))
            SizedBox(width: s.md),
          if (_hasFilterTrigger || _hasActions)
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
                    if (_hasFilterTrigger) _buildFiltersButton(context),
                    if (_hasActions) ...toolbarActions!,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: EnterpriseSearchField(
        controller: searchController!,
        hintText: searchHint ?? 'Pesquisar...',
        onChanged: onSearchChanged ?? (_) {},
      ),
    );
  }

  Widget _buildMobileActionsRow(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final actions = toolbarActions ?? const <Widget>[];

    // Em mobile: Filtros à esquerda; acções secundárias no menu ▾.
    return Row(
      children: [
        if (_hasFilterTrigger)
          Expanded(child: _buildFiltersButton(context, expanded: true)),
        if (_hasFilterTrigger && actions.isNotEmpty) SizedBox(width: s.sm),
        if (actions.length == 1)
          Flexible(child: actions.first)
        else if (actions.length > 1)
          PopupMenuButton<int>(
            enabled: enabled,
            tooltip: 'Acções',
            position: PopupMenuPosition.under,
            icon: Icon(Icons.more_horiz_rounded, size: t.iconMd),
            itemBuilder: (menuContext) => [
              for (var i = 0; i < actions.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  padding: EdgeInsets.symmetric(
                    horizontal: s.md,
                    vertical: s.xs,
                  ),
                  child: actions[i],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildFiltersButton(BuildContext context, {bool expanded = false}) {
    return Builder(
      builder: (buttonContext) {
        final button = _FiltersButton(
          enabled: enabled,
          hasActiveFilters: hasActiveFilters,
          expanded: expanded,
          onPressed: () => _openFilters(context, buttonContext),
        );
        return button;
      },
    );
  }

  void _openFilters(BuildContext context, BuildContext anchorContext) {
    if (onOpenFilters != null) {
      onOpenFilters!();
      return;
    }

    final panelFilters = _resolvedFilters;
    if (panelFilters.isEmpty) return;

    EnterpriseTableFilterPanel.present(
      context: context,
      anchorContext: anchorContext,
      filters: panelFilters,
      title: filterTitle,
      onClear: onClearFilters,
      onApply: onApplyFilters ?? () {},
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({
    required this.enabled,
    required this.hasActiveFilters,
    required this.onPressed,
    this.expanded = false,
  });

  final bool enabled;
  final bool hasActiveFilters;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final style = PharmaComponentTheme.outlined(
      t,
      scheme,
      compact: true,
    );

    final label = hasActiveFilters ? 'Filtros *' : 'Filtros';
    final button = OutlinedButton.icon(
      style: style,
      onPressed: enabled ? onPressed : null,
      icon: Icon(Icons.filter_list_rounded, size: t.iconSm),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!expanded) ...[
            SizedBox(width: context.spacing.xxs),
            Icon(Icons.arrow_drop_down_rounded, size: t.iconSm),
          ],
        ],
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
