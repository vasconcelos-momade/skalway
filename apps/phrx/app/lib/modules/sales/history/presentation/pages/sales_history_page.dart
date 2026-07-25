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
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../../../invoices/presentation/providers/invoice_detail_provider.dart';
import '../../../invoices/presentation/widgets/invoice_detail_screen.dart';
import '../../../invoices/presentation/widgets/invoice_status_badge.dart';
import '../../domain/entities/sales_history.dart';
import '../providers/sales_history_provider.dart';

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
    final s = context.spacing;
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

    return EnterpriseModuleHub(
      title: 'Histórico de vendas',
      subtitle: 'Drill-down por terminal, operador e linha de receita.',
      tag: 'Terminal',
      actions: [
        PopupMenuButton<String>(
          enabled: state.items.isNotEmpty && !reportState.isSubmitting,
          tooltip: 'Exportar',
          onSelected: (value) {
            if (value == 'pdf') {
              reportController.downloadPdf(
                path: ReportPaths.salesHistory,
                queryParameters: reportQuery,
              );
              return;
            }
            reportController.exportCsv(
              path: ReportPaths.salesHistory,
              queryParameters: reportQuery,
            );
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'pdf', child: Text('Exportar PDF')),
            PopupMenuItem<String>(value: 'csv', child: Text('Exportar CSV')),
          ],
          child: OutlinedButton.icon(
            onPressed: null,
            icon: Icon(Icons.download_outlined),
            label: Text('Exportar'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Nº fatura, cliente ou terminal...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
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
          if (state.query.hasFilters)
            TextButton.icon(
              onPressed: state.isBusy ? null : notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar'),
            ),
        ],
      ),
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
            columns: [
              for (final label in [
                'Fatura',
                'Cliente',
                'Terminal',
                'Total',
                'Estado',
                'Data',
              ])
                DataColumn(
                  label: Text(
                    label.toUpperCase(),
                    style: TableTypography.header(context),
                  ),
                ),
            ],
            rowCount: state.items.length,
            rowBuilder: (context, index) {
              final inv = state.items[index];
              return DataRow(
                onSelectChanged: (_) => _openInvoiceDetail(inv),
                cells: [
                  DataCell(
                    Text(inv.numero, style: TableTypography.primary(context)),
                  ),
                  DataCell(
                    Text(
                      inv.cliente?.nome ?? '—',
                      style: Theme.of(context).textTheme.erpBodySecondary
                          .copyWith(color: t.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      inv.terminal?.codigo ?? inv.terminal?.nome ?? '—',
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${_currency.format(inv.total)} MT',
                      style: TableTypography.primary(
                        context,
                        color: t.brandGreen,
                      ),
                    ),
                  ),
                  DataCell(InvoiceStatusBadge(status: inv.estado)),
                  DataCell(
                    Text(
                      _dateTime.format(inv.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
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
