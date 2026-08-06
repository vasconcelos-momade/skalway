import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

/// Logs de auditoria da plataforma Central.
class PlatformAuditLogsPage extends ConsumerStatefulWidget {
  const PlatformAuditLogsPage({super.key});

  @override
  ConsumerState<PlatformAuditLogsPage> createState() =>
      _PlatformAuditLogsPageState();
}

class _PlatformAuditLogsPageState extends ConsumerState<PlatformAuditLogsPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformAuditLogEntry> _accumulated = [];
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(platformAuditLogsProvider);
    final notifier = ref.read(platformAuditLogsProvider.notifier);

    if (_searchCtrl.text != state.search) {
      _searchCtrl.value = TextEditingValue(
        text: state.search,
        selection: TextSelection.collapsed(offset: state.search.length),
      );
    }

    ref.listen(platformAuditLogsProvider, (previous, next) {
      if (previous?.page != next.page || previous?.search != next.search) {
        if (next.page == 1) {
          _accumulated
            ..clear()
            ..addAll(next.items);
        } else {
          _accumulated.addAll(
            next.items.where((e) => !_accumulated.any((a) => a.id == e.id)),
          );
        }
      } else if (previous?.items != next.items && next.page == 1) {
        _accumulated
          ..clear()
          ..addAll(next.items);
      }
    });

    if (state.page == 1 &&
        _accumulated.isEmpty &&
        state.items.isNotEmpty) {
      _accumulated.addAll(state.items);
    }

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: () => notifier.refresh(),
          child: EnterpriseModuleHub(
            title: 'Auditoria',
            subtitle: 'Trilho de auditoria da plataforma Central.',
            tag: 'Plataforma',
            filters: null,
            child: _buildBody(
              context,
              isMobile: isMobile,
              state: state,
              notifier: notifier,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isMobile,
    required PlatformAuditListState state,
    required PlatformAuditLogsController notifier,
  }) {
    final desktopItems = state.items;
    final mobileItems = _accumulated.isNotEmpty ? _accumulated : state.items;
    final isLoading = state.isBusy;
    final errorText = state.viewState == PlatformAuditViewState.error
        ? state.errorMessage
        : null;

    return EnterpriseAdaptiveListBody(
      isMobile: isMobile,
      isLoading: isLoading,
      errorText: errorText,
      desktopContent: EnterpriseDataTable(
        adaptive: false,
        showCheckboxColumn: false,
        searchController: _searchCtrl,
        searchHint: 'Acção, entidade, caminho…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading && desktopItems.isEmpty,
        errorMessage: desktopItems.isEmpty ? errorText : null,
        errorTitle: 'Erro ao carregar logs',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Nenhum log encontrado.',
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Acção')),
          DataColumn(label: Text('Entidade')),
          DataColumn(label: Text('Tenant')),
          DataColumn(label: Text('Utilizador')),
          DataColumn(label: Text('IP')),
        ],
        rowCount: desktopItems.length,
        rowBuilder: (context, index) {
          final log = desktopItems[index];
          return DataRow(
            cells: [
              DataCell(Text(_dateTime.format(log.createdAt.toLocal()))),
              DataCell(Text(log.action)),
              DataCell(
                Text(
                  log.entityId == null
                      ? log.entity
                      : '${log.entity} #${log.entityId}',
                ),
              ),
              DataCell(
                Text(log.tenantName ?? log.tenantKey ?? '—'),
              ),
              DataCell(Text(log.userName ?? '—')),
              DataCell(Text(log.ip ?? '—')),
            ],
          );
        },
        pagination: state.totalCount != null
            ? EnterprisePagination(
                page: state.page,
                pageSize: state.pageSize,
                totalCount: state.totalCount!,
                isBusy: isLoading,
                itemLabel: 'logs',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      desktopPagination: null,
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Acção, entidade, caminho…',
          enabled: !state.isBusy,
          isLoading: state.isBusy,
          hasFilters: false,
          showFiltersButton: false,
          onSearchSubmitted: notifier.setSearch,
          onOpenFilters: () {},
        ),
        itemCount: mobileItems.length,
        hasMore: state.hasMore,
        isLoading: state.isBusy,
        emptyMessage: 'Nenhum log encontrado.',
        onLoadMore: state.hasMore && !state.isBusy
            ? () => notifier.goToPage(state.page + 1)
            : null,
        itemBuilder: (context, index) {
          final log = mobileItems[index];
          return Column(
            children: [
              if (index > 0) const EnterpriseListDivider(),
              EnterpriseListCard(
                title: log.action,
                subtitle: log.entityId == null
                    ? log.entity
                    : '${log.entity} #${log.entityId}',
                metadata: [
                  EnterpriseListCardMeta(
                    label: _dateTime.format(log.createdAt.toLocal()),
                  ),
                  if (log.tenantName != null || log.tenantKey != null)
                    EnterpriseListCardMeta(
                      label: log.tenantName ?? log.tenantKey!,
                    ),
                  EnterpriseListCardMeta(
                    label: log.userName ?? 'Sistema',
                  ),
                  if (log.ip != null)
                    EnterpriseListCardMeta(label: 'IP ${log.ip}'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
