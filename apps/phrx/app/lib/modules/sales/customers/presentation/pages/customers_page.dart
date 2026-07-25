import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../reports/presentation/controllers/report_controller.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_list_provider.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../widgets/customer_form_sheet.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  late final TextEditingController _searchController;
  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(customerListProvider).query.search,
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
    final state = ref.watch(customerListProvider);
    final notifier = ref.read(customerListProvider.notifier);
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
      title: 'Clientes & convénios',
      subtitle: 'CRM operacional, limites de crédito e convénios hospitalares.',
      tag: 'Terminal',
      actions: [
        PopupMenuButton<String>(
          enabled: !state.isBusy && !reportState.isSubmitting,
          tooltip: 'Exportar',
          onSelected: (value) {
            if (value == 'pdf') {
              reportController.downloadPdf(
                path: ReportPaths.customers,
                queryParameters: reportQuery,
              );
              return;
            }
            reportController.exportCsv(
              path: ReportPaths.customers,
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
        FilledButton.icon(
          onPressed: state.isBusy ? null : () => _openCreateSheet(context),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Novo cliente'),
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
                hintText: 'Nome, NUIT, telefone ou email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: EnterpriseSelectField<String>(
              label: 'Tipo',
              emptyLabel: 'Todos os tipos',
              value: state.query.tipo,
              options: const [
                EnterpriseSelectOption<String>(
                  value: 'PACIENTE',
                  label: 'Paciente',
                ),
                EnterpriseSelectOption<String>(
                  value: 'EMPRESA',
                  label: 'Empresa',
                ),
                EnterpriseSelectOption<String>(
                  value: 'CONVENIO',
                  label: 'Convénio',
                ),
              ],
              onChanged: state.isBusy ? null : notifier.setTipoFilter,
            ),
          ),
          FilterChip(
            label: const Text('Com crédito'),
            selected: state.query.comCredito == true,
            onSelected: state.isBusy
                ? null
                : (_) => notifier.setComCreditoFilter(
                    state.query.comCredito == true ? null : true,
                  ),
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
          title: 'Total clientes',
          value: '${dash.totalClientes}',
          icon: Icons.people_outline,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Novos este mês',
          value: '${dash.novosClientes}',
          icon: Icons.person_add_outlined,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Activos (90 dias)',
          value: '${dash.clientesAtivos}',
          icon: Icons.verified_outlined,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Com saldo',
          value: '${dash.clientesComCredito}',
          icon: Icons.account_balance_wallet_outlined,
          accent: StatCardAccent.warning,
        ),
      ],
      child: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerListState state,
    CustomerListController notifier,
  ) {
    if (state.viewState == CustomerViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == CustomerViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar clientes',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.people_outline,
      );
    }
    if (state.viewState == CustomerViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhum cliente encontrado',
        subtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros para ver mais resultados.'
            : 'Ainda não existem clientes registados.',
        onClearFilters: state.query.hasFilters ? notifier.clearFilters : null,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              state.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.erpCaption.copyWith(color: t.posWarning),
            ),
          ),
        Expanded(
          child: EnterpriseDataTable(
            columns: [
              for (final label in [
                'Cliente',
                'Tipo',
                'NUIT',
                'Saldo',
                'Faturas',
                'Registo',
                'Ações',
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
              final c = state.items[index];
              return DataRow(
                cells: [
                  DataCell(
                    Text(c.nome, style: TableTypography.primary(context)),
                  ),
                  DataCell(
                    Text(
                      _tipoLabel(c.tipo),
                      style: Theme.of(context).textTheme.erpBodySecondary
                          .copyWith(color: t.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      c.nuit ?? '—',
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${_currency.format(c.saldoAtual)} MT',
                      style: TableTypography.primary(
                        context,
                        color: c.saldoAtual > 0 ? t.posWarning : t.brandGreen,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${c.faturaCount}',
                      style: Theme.of(
                        context,
                      ).textTheme.erpBodySecondary.copyWith(color: t.brandBlue),
                    ),
                  ),
                  DataCell(
                    Text(
                      dateFmt.format(c.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
                  DataCell(
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Ações',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditSheet(context, c);
                        } else if (value == 'contas') {
                          // TODO: Navigate to Contas a Pagar or perform related action
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        if (c.tipo == 'EMPRESA' || c.tipo == 'FIADO')
                          const PopupMenuItem(
                            value: 'contas',
                            child: Text('Contas a Pagar'),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            hasMore: state.hasMore,
            isLoading: state.isBusy,
            onLoadMore: () => notifier.goToPage(state.query.page + 1),
            onRefresh: notifier.refresh,
          ),
        ),
      ],
    );
  }

  String _tipoLabel(String tipo) => switch (tipo) {
    'EMPRESA' => 'Empresa',
    'CONVENIO' => 'Convénio',
    _ => 'Paciente',
  };

  Future<void> _openEditSheet(
    BuildContext context,
    CustomerSummary customer,
  ) async {
    final detail = await ref
        .read(customerRepositoryProvider)
        .getCustomer(customer.id);
    if (!context.mounted) return;
    final result = await showCustomerFormSheet(context, customer: detail);
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(customerListProvider.notifier)
          .updateCustomer(customer.id, result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Cliente actualizado');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final result = await showCustomerFormSheet(context);
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(customerListProvider.notifier)
          .createCustomer(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Cliente criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Map<String, dynamic> _buildReportQuery(CustomerQuery query) {
    return <String, dynamic>{
      if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
      if (query.tipo != null) 'tipo': query.tipo,
      if (query.comCredito != null) 'comCredito': query.comCredito.toString(),
      if (query.temPrescricao != null)
        'temPrescricao': query.temPrescricao.toString(),
    };
  }
}
