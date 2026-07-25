import 'package:flutter/material.dart';

import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../providers/audit_providers.dart';

typedef AuditMobileCardBuilder<T> = Widget Function(T item);
typedef AuditRowBuilder<T> = DataRow Function(T item);
typedef AuditItemId<T> = String Function(T item);

/// Corpo adaptativo para listagens de auditoria (logs, cronologia).
class AuditAdaptiveListBody<T> extends StatefulWidget {
  const AuditAdaptiveListBody({
    super.key,
    required this.state,
    required this.searchController,
    required this.searchHint,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.errorTitle,
    required this.errorIcon,
    required this.columns,
    required this.rowBuilder,
    required this.mobileCardBuilder,
    required this.itemId,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onGoToPage,
    required this.onPageSizeChanged,
    this.headerActions = const [],
    this.accumulatedItems = const [],
    this.kpis,
  });

  final AuditListState<T> state;
  final TextEditingController searchController;
  final String searchHint;
  final String emptyTitle;
  final String emptySubtitle;
  final String errorTitle;
  final IconData errorIcon;
  final List<DataColumn> columns;
  final AuditRowBuilder<T> rowBuilder;
  final AuditMobileCardBuilder<T> mobileCardBuilder;
  final AuditItemId<T> itemId;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onRefresh;
  final ValueChanged<int> onGoToPage;
  final ValueChanged<int> onPageSizeChanged;
  final List<Widget> headerActions;
  final List<T> accumulatedItems;
  final List<Widget>? kpis;

  @override
  State<AuditAdaptiveListBody<T>> createState() => _AuditAdaptiveListBodyState<T>();
}

class _AuditAdaptiveListBodyState<T> extends State<AuditAdaptiveListBody<T>> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;
        final state = widget.state;

        return EnterpriseAdaptiveListBody(
          isMobile: isMobile,
          isLoading: state.isBusy,
          errorText: state.viewState == AuditViewState.error ? state.errorMessage : null,
          desktopToolbar: EnterpriseDesktopListToolbar(
            searchController: widget.searchController,
            searchHint: widget.searchHint,
            isLoading: state.isBusy,
            onSearchSubmitted: widget.onSearchChanged,
            hasFilters: state.query.hasFilters,
            onClearFilters: widget.onClearFilters,
            filterWidgets: const [],
            trailingActions: widget.headerActions,
          ),
          desktopContent: _buildDesktopContent(context),
          desktopPagination: state.viewState == AuditViewState.loaded
              ? EnterprisePagination(
                  page: state.query.page,
                  pageSize: state.query.pageSize,
                  totalCount: state.totalCount,
                  hasMore: state.hasMore,
                  itemsOnPage: state.items.length,
                  isBusy: state.isBusy,
                  onPageChanged: widget.onGoToPage,
                  onPageSizeChanged: widget.onPageSizeChanged,
                )
              : null,
          mobileList: EnterpriseMobileScrollList(
            kpis: widget.kpis,
            stickyHeader: EnterpriseMobileToolbar(
              searchController: widget.searchController,
              searchHint: widget.searchHint,
              enabled: !state.isBusy,
              isLoading: state.isBusy,
              hasFilters: state.query.hasFilters,
              showFiltersButton: false,
              onSearchSubmitted: widget.onSearchChanged,
              onOpenFilters: () {},
              onClearFilters: () async => widget.onClearFilters(),
              onRefresh: widget.onRefresh,
            ),
            itemCount: widget.accumulatedItems.length,
            itemBuilder: (context, index) =>
                widget.mobileCardBuilder(widget.accumulatedItems[index]),
            hasMore: state.hasMore,
            isLoading: state.isBusy,
            onLoadMore: () => widget.onGoToPage(state.query.page + 1),
            emptyMessage: widget.emptyTitle,
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    final state = widget.state;

    if (state.viewState == AuditViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == AuditViewState.error) {
      return ModuleErrorState(
        title: widget.errorTitle,
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: widget.onRefresh,
        icon: widget.errorIcon,
      );
    }
    if (state.viewState == AuditViewState.empty) {
      return ModuleEmptyState(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
        onClearFilters: state.query.hasFilters ? widget.onClearFilters : null,
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: widget.columns,
      rowCount: state.items.length,
      rowBuilder: (context, index) => widget.rowBuilder(state.items[index]),
    );
  }
}
