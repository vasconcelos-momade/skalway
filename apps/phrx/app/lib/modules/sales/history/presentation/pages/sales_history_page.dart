import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../reports/presentation/controllers/report_controller.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../../../../core/theme/component_theme.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../../../invoices/presentation/providers/invoice_detail_provider.dart';
import '../../../invoices/presentation/widgets/invoice_detail_screen.dart';
import '../../../invoices/presentation/widgets/invoice_status_badge.dart';
import '../../domain/entities/sales_history.dart';
import '../providers/sales_history_provider.dart';
import '../../../../../shared/refresh/page_refresh.dart';

class SalesHistoryPage extends ConsumerStatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  ConsumerState<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends ConsumerState<SalesHistoryPage> {
  late final TextEditingController _searchController;
  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(salesHistoryProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesHistoryProvider);
    final notifier = ref.read(salesHistoryProvider.notifier);
    final reportState = ref.watch(reportControllerProvider);
    final reportController = ref.read(reportControllerProvider.notifier);
    final dash = state.dashboard;
    final reportQuery = _buildReportQuery(state.query);

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    return PageRefreshBinder(
      onRefresh: () => notifier.refresh(),
      child: EnterpriseModuleHub(
      title: 'Histórico de vendas',
      subtitle: 'Drill-down por terminal, operador e linha de receita.',
      tag: 'Terminal',
      actions: [
        Builder(
          builder: (anchorContext) {
            final t = context.pharmaTokens;
            final compactStyle = PharmaComponentTheme.outlined(
              t,
              Theme.of(context).colorScheme,
              compact: true,
            );
            return OutlinedButton.icon(
              style: compactStyle,
              onPressed: state.items.isEmpty || reportState.isSubmitting
                  ? null
                  : () async {
                      final selected =
                          await showEnterpriseDropdownMenuFrom<String>(
                        context: context,
                        anchorContext: anchorContext,
                        items: const [
                          EnterpriseDropdownItem(
                            value: 'pdf',
                            label: 'Exportar PDF',
                            icon: Icons.picture_as_pdf_outlined,
                          ),
                          EnterpriseDropdownItem(
                            value: 'csv',
                            label: 'Exportar CSV',
                            icon: Icons.table_chart_outlined,
                          ),
                        ],
                      );
                      if (selected == 'pdf') {
                        reportController.downloadPdf(
                          path: ReportPaths.salesHistory,
                          queryParameters: reportQuery,
                        );
                      } else if (selected == 'csv') {
                        reportController.exportCsv(
                          path: ReportPaths.salesHistory,
                          queryParameters: reportQuery,
                        );
                      }
                    },
              icon: Icon(Icons.download_outlined, size: t.iconSm),
              label: const Text('Exportar'),
            );
          },
        ),
      ],
      filters: null,
      kpis: [
        EnterpriseStatCard(
          title: 'Vendas',
          value: '${dash.totalVendas}',
          subtitle: 'No período filtrado',
          icon: Icons.point_of_sale_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Receita',
          value: '${_currency.format(dash.receitaTotal)} MT',
          icon: Icons.payments_outlined,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Ticket médio',
          value: '${_currency.format(dash.ticketMedio)} MT',
          icon: Icons.receipt_long_outlined,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Pagas',
          value: '${state.summary.paid}',
          subtitle: 'Lista actual',
          icon: Icons.check_circle_outline,
          accent: StatCardAccent.positive,
        ),
      ],
      child: _buildBody(context, state, notifier),
    ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SalesHistoryState state,
    SalesHistoryController notifier,
  ) {
    if (state.viewState == SalesHistoryViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == SalesHistoryViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar histórico',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.history,
      );
    }
    if (state.viewState == SalesHistoryViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhuma venda encontrada',
        subtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros para ver mais resultados.'
            : 'Ainda não existem vendas registadas.',
        onClearFilters: state.query.hasFilters ? notifier.clearFilters : null,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dashHasTopProducts(state))
          Padding(
            padding: EdgeInsets.only(bottom: s.md),
            child: Wrap(
              spacing: s.sm,
              children: [
                for (final p in state.dashboard.topProdutos.take(3))
                  Chip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('${p.nome}: ${_currency.format(p.receita)} MT'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: EnterpriseDataTable(
            searchController: _searchController,
            searchHint: 'Nº fatura, cliente ou terminal...',
            onSearchChanged: notifier.onSearchChanged,
            filters: [
              for (final filter in SalesHistoryQuickFilter.values.where(
                (f) => f != SalesHistoryQuickFilter.none,
              ))
                FilterChip(
                  label: Text(_quickFilterLabel(filter)),
                  selected: state.query.quickFilter == filter,
                  onSelected: state.isBusy
                      ? null
                      : (_) => notifier.setQuickFilter(filter),
                ),
            ],
            hasActiveFilters:
                state.query.quickFilter != SalesHistoryQuickFilter.none,
            onClearFilters: () =>
                notifier.setQuickFilter(SalesHistoryQuickFilter.none),
            onApplyFilters: () {},
            showCheckboxColumn: false,
            columns: [
              for (final label in [
                'Fatura',
                'Cliente',
                'Terminal',
                'Total',
                'Estado',
                'Data',
              ])
                enterpriseDataColumn(
                  context,
                  label,
                  numeric: label == 'Total',
                ),
            ],
            rowCount: state.items.length,
            rowBuilder: (context, index) {
              final inv = state.items[index];
              return DataRow(
                onSelectChanged: (_) => _openInvoiceDetail(inv),
                cells: [
                  DataCell(TablePrimaryCell(inv.numero)),
                  DataCell(TableSecondaryCell(inv.cliente?.nome ?? '—')),
                  DataCell(
                    TableMetadataCell(
                      inv.terminal?.codigo ?? inv.terminal?.nome,
                    ),
                  ),
                  DataCell(
                    TableNumericCell(
                      '${_currency.format(inv.total)} MT',
                      color: t.brandGreen,
                    ),
                  ),
                  DataCell(InvoiceStatusBadge(status: inv.estado)),
                  DataCell(TableMetadataCell(_dateTime.format(inv.createdAt))),
                ],
              );
            },
          ),
        ),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: state.query.page,
          pageSize: state.query.pageSize,
          hasMore: state.hasMore,
          isBusy: state.isBusy,
          onPrev: state.query.page > 1
              ? () => notifier.goToPage(state.query.page - 1)
              : null,
          onNext: state.hasMore
              ? () => notifier.goToPage(state.query.page + 1)
              : null,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }

  bool dashHasTopProducts(SalesHistoryState state) =>
      state.dashboard.topProdutos.isNotEmpty;

  String _quickFilterLabel(SalesHistoryQuickFilter filter) => switch (filter) {
    SalesHistoryQuickFilter.today => 'Hoje',
    SalesHistoryQuickFilter.week => 'Semana',
    SalesHistoryQuickFilter.month => 'Mês',
    SalesHistoryQuickFilter.none => 'Todas',
  };

  Future<void> _openInvoiceDetail(InvoiceSummary invoice) async {
    ref.read(invoiceDetailProvider.notifier).open(invoice);

    await AdaptiveNavigator.openPanel<void>(
      context: context,
      routeSettings: RouteSettings(name: '/faturas/${invoice.id}'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return InvoiceDetailScreen(invoice: invoice);
        }
        return InvoiceDetailPanel(
          invoice: invoice,
          onClose: () => AdaptiveNavigator.close(detailContext),
        );
      },
    );

    ref.read(invoiceDetailProvider.notifier).close();
  }

  Map<String, dynamic> _buildReportQuery(SalesHistoryQuery query) {
    String? formatDate(DateTime? value) {
      if (value == null) {
        return null;
      }
      final year = value.year.toString().padLeft(4, '0');
      final month = value.month.toString().padLeft(2, '0');
      final day = value.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    return <String, dynamic>{
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.status != null) 'status': query.status,
      if (query.dateFrom != null) 'dateFrom': formatDate(query.dateFrom),
      if (query.dateTo != null) 'dateTo': formatDate(query.dateTo),
    };
  }
}
