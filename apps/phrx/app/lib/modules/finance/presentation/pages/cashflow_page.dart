import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../dashboard/domain/dashboard_query.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../shared/widgets/dashboard/enterprise_filter_bar.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../data/repositories/cashflow_repository_impl.dart';
import '../../domain/entities/cashflow_operation.dart';
import '../widgets/cashflow_operation_dialog.dart';
import '../widgets/finance_report_exports.dart';
import '../widgets/cashflow_table.dart';
import '../widgets/cashflow_mobile_card.dart';

class CashflowPage extends ConsumerStatefulWidget {
  const CashflowPage({super.key});

  @override
  ConsumerState<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends ConsumerState<CashflowPage> {
  var _query = const DashboardQuery();
  var _tableReloadToken = 0;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _accumulatedItems = [];
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;
  int? _totalCount;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTable();
    });
  }

  Future<void> _fetchTable() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(cashflowRepositoryProvider);
      final result = await repository.listMovements(
        queryParameters: _query.toParams(),
        page: _page,
        pageSize: _pageSize,
        sortBy: null,
        sortDir: 'desc',
      );

      if (!mounted) return;

      setState(() {
        _items = result.items.map((row) => <String, dynamic>{
          'id': row.id,
          'data': row.data,
          'tipo': row.tipo,
          'valor': row.valor,
          'saldoAnterior': row.saldoAnterior,
          'saldoFinal': row.saldoFinal,
          'descricao': row.descricao,
        }).toList();

        if (_page == 1) {
          _accumulatedItems = List.of(_items);
        } else {
          final newItems = _items.where((e) => !_accumulatedItems.any((a) => a['id'] == e['id'])).toList();
          _accumulatedItems.addAll(newItems);
        }

        _totalCount = result.totalCount;
        _hasMore = result.hasMore;
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _isInitialized = true;
      });
    }
  }

  void _onQueryChanged(DashboardQuery query) {
    setState(() {
      _query = query;
      _page = 1;
    });
    _fetchTable();
  }

  Future<void> _openOperation(CashflowOperationKind kind) async {
    final result = await showCashflowOperationDialog(context, kind: kind);
    if (!mounted || result == null) return;

    setState(() => _tableReloadToken++);
    invalidateExecutiveAndFinanceDashboardsFrom(ref);
    _page = 1;
    _fetchTable();

    PharmaFeedback.success(
      context,
      '${kind.label} registada. Novo saldo: ${formatCashflowMoney(result.saldoAtual)}',
    );
  }

  Future<void> _refreshPage() async {
    setState(() => _tableReloadToken++);
    invalidateExecutiveAndFinanceDashboardsFrom(ref);
    _page = 1;
    await _fetchTable();
    try {
      await ref.read(financeDashboardProvider(_query).future);
    } catch (_) {}
  }

  String _formatDateTime(String iso) {
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return iso.isEmpty ? '—' : iso;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year.toString();
    final h = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _formatMoney(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);
    final parsed = num.tryParse(value?.toString() ?? '');
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);

    // Apenas operação de caixa (saldo físico). Receita/Faturamento vive noutro menu.
    final kpiCards = kpis == null
        ? null
        : [
            dashboardKpiCard(
              title: 'Saldo inicial',
              value: '${dashKpi(kpis, 'saldoInicial')} MZN',
              icon: Icons.playlist_add_check_circle_outlined,
              accent: StatCardAccent.neutral,
            ),
            dashboardKpiCard(
              title: 'Vendas',
              value: '${dashKpi(kpis, 'vendas')} MZN',
              icon: Icons.point_of_sale_outlined,
              accent: StatCardAccent.positive,
            ),
            dashboardKpiCard(
              title: 'Suprimentos',
              value: '${dashKpi(kpis, 'suprimentos')} MZN',
              icon: Icons.add_circle_outline,
              accent: StatCardAccent.positive,
            ),
            dashboardKpiCard(
              title: 'Despesas',
              value: '${dashKpi(kpis, 'despesasCaixa')} MZN',
              icon: Icons.remove_circle_outline,
              accent: StatCardAccent.warning,
            ),
            dashboardKpiCard(
              title: 'Sangrias',
              value: '${dashKpi(kpis, 'sangrias')} MZN',
              icon: Icons.savings_outlined,
              accent: StatCardAccent.warning,
            ),
            dashboardKpiCard(
              title: 'Estornos',
              value: '${dashKpi(kpis, 'estornos')} MZN',
              icon: Icons.settings_backup_restore_outlined,
              accent: StatCardAccent.info,
            ),
            dashboardKpiCard(
              title: 'Saldo final',
              value: '${dashKpi(kpis, 'saldoFinal')} MZN',
              icon: Icons.account_balance_wallet,
              accent: StatCardAccent.positive,
            ),
          ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.isDesktopOrWider;
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: _refreshPage,
          child: EnterpriseModuleHub(
          title: 'Fluxo de caixa',
          subtitle: 'Movimentações que alteram o saldo físico do caixa.',
          scrollable: false,
          mobileKpisHorizontalScroll: true,
          kpis: isMobile ? null : kpiCards,
          filters: null,
          actions: isMobile
              ? null
              : [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openOperation(CashflowOperationKind.despesaOperacional),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Despesa operacional'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openOperation(CashflowOperationKind.compraEstoque),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Compra estoque'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openOperation(CashflowOperationKind.suprimento),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Suprimento'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openOperation(CashflowOperationKind.sangria),
                    icon: const Icon(Icons.savings_outlined),
                    label: const Text('Sangria'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openOperation(CashflowOperationKind.estorno),
                    icon: const Icon(Icons.settings_backup_restore_outlined),
                    label: const Text('Estorno'),
                  ),
                ],
          child: EnterpriseAdaptiveListBody(
            isMobile: isMobile,
            isLoading: !_isInitialized && _isLoading,
            errorText: _errorMessage != null && _items.isEmpty ? _errorMessage : null,
            desktopToolbar: isMobile ? null : _buildDesktopToolbar(reportState),
            desktopContent: !_isInitialized && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _items.isEmpty
                    ? Center(child: Text('Erro: $_errorMessage'))
                    : (isDesktop ? _items.isEmpty : _accumulatedItems.isEmpty)
                        ? const Center(child: Text('Sem resultados para os filtros selecionados.'))
                        : CashflowTable(
                            items: _items,
                            formatDateTime: _formatDateTime,
                            formatMoney: _formatMoney,
                          ),
            desktopPagination: _isInitialized && _totalCount != null
                ? MovimentacoesPagination(
                    page: _page,
                    pageSize: _pageSize,
                    totalCount: _totalCount,
                    hasMore: _hasMore,
                    isBusy: _isLoading,
                    onPageChanged: (nextPage) {
                      setState(() => _page = nextPage);
                      _fetchTable();
                    },
                    onPageSizeChanged: (value) {
                      setState(() {
                        _page = 1;
                        _pageSize = value;
                      });
                      _fetchTable();
                    },
                  )
                : null,
            mobileList: EnterpriseMobileScrollList(
              kpis: kpiCards,
              stickyHeader: _buildMobileToolbar(reportState),
              itemCount: _accumulatedItems.length,
              itemBuilder: (context, index) {
                return CashflowMobileCard(
                  row: _accumulatedItems[index],
                  formatDateTime: _formatDateTime,
                  formatMoney: _formatMoney,
                );
              },
              hasMore: _hasMore,
              isLoading: _isLoading,
              onLoadMore: () {
                setState(() => _page++);
                _fetchTable();
              },
              emptyMessage: 'Nenhum movimento encontrado',
              totalCount: _totalCount,
              totalCountLabel: _totalCount != null ? 'Total: $_totalCount movimento(s)' : null,
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopToolbar(ReportActionState reportState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EnterpriseFilterBar(
            query: _query,
            onChanged: _onQueryChanged,
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            ...financeReportActions(
              ref: ref,
              enabled: !reportState.isSubmitting && !_isLoading,
              path: ReportPaths.financeCashflow,
              queryParameters: _query.toParams(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileToolbar(ReportActionState reportState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: EnterpriseFilterBar(
            query: _query,
            onChanged: _onQueryChanged,
          ),
        ),
        const SizedBox(height: 8),
        financeReportActions(
          ref: ref,
          enabled: !reportState.isSubmitting && !_isLoading,
          path: ReportPaths.financeCashflow,
          queryParameters: _query.toParams(),
        ).first,
      ],
    );
  }
}
