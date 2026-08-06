import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/plan_form_side_sheet.dart';

class PlatformPlansPage extends ConsumerStatefulWidget {
  const PlatformPlansPage({super.key});

  @override
  ConsumerState<PlatformPlansPage> createState() => _PlatformPlansPageState();
}

class _PlatformPlansPageState extends ConsumerState<PlatformPlansPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformPlan> _accumulated = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformPlansProvider);
    final busy = ref.watch(platformBillingActionsProvider);
    final notifier = ref.read(platformPlansProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);

    if (_searchCtrl.text != notifier.search) {
      _searchCtrl.value = TextEditingValue(
        text: notifier.search,
        selection: TextSelection.collapsed(offset: notifier.search.length),
      );
    }

    ref.listen(platformPlansProvider, (previous, next) {
      final data = next.asData?.value;
      if (data == null) return;
      final prevData = previous?.asData?.value;
      if (data.page == 1) {
        _accumulated
          ..clear()
          ..addAll(data.items);
      } else if (prevData?.page != data.page) {
        _accumulated.addAll(
          data.items.where((e) => !_accumulated.any((a) => a.id == e.id)),
        );
      }
    });

    final pageData = async.asData?.value;
    if (pageData != null &&
        pageData.page == 1 &&
        _accumulated.isEmpty &&
        pageData.items.isNotEmpty) {
      _accumulated.addAll(pageData.items);
    }

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: () => notifier.refresh(),
          child: EnterpriseModuleHub(
            title: 'Planos',
            subtitle: 'Catálogo de planos da operação SaaS.',
            tag: 'Plataforma',
            actions: isMobile
                ? null
                : [
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _createOrEdit(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Novo plano'),
                    ),
                  ],
            child: async.when(
              loading: () => _accumulated.isEmpty
                  ? const ModuleLoadingState()
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      plans: _accumulated,
                      page: pageData?.page ?? notifier.page,
                      pageSize: pageData?.pageSize ?? notifier.pageSize,
                      hasMore: pageData?.hasMore ?? false,
                      totalCount: pageData?.totalCount,
                      isLoading: true,
                      busy: busy,
                      currency: currency,
                      notifier: notifier,
                    ),
              error: (e, _) => _accumulated.isEmpty
                  ? ModuleErrorState(
                      title: 'Erro ao carregar planos',
                      message: e.toString(),
                      onRetry: () => notifier.refresh(),
                    )
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      plans: _accumulated,
                      page: notifier.page,
                      pageSize: notifier.pageSize,
                      hasMore: false,
                      totalCount: null,
                      isLoading: false,
                      errorText: e.toString(),
                      busy: busy,
                      currency: currency,
                      notifier: notifier,
                    ),
              data: (page) => _buildBody(
                context,
                isMobile: isMobile,
                plans: isMobile ? _accumulated : page.items,
                page: page.page,
                pageSize: page.pageSize,
                hasMore: page.hasMore,
                totalCount: page.totalCount,
                isLoading: false,
                busy: busy,
                currency: currency,
                notifier: notifier,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isMobile,
    required List<PlatformPlan> plans,
    required int page,
    required int pageSize,
    required bool hasMore,
    required int? totalCount,
    required bool isLoading,
    required bool busy,
    required NumberFormat currency,
    required PlatformPlansNotifier notifier,
    String? errorText,
  }) {
    return EnterpriseAdaptiveListBody(
      isMobile: isMobile,
      isLoading: isLoading,
      errorText: errorText,
      desktopContent: EnterpriseDataTable(
        adaptive: false,
        showCheckboxColumn: false,
        searchController: _searchCtrl,
        searchHint: 'Pesquisar plano ou slug…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading,
        errorMessage: errorText,
        errorTitle: 'Erro ao carregar planos',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Sem planos.',
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Slug')),
          DataColumn(label: Text('Preço Mensal')),
          DataColumn(label: Text('Filiais')),
          DataColumn(label: Text('Extra')),
          DataColumn(label: Text('Trial')),
          DataColumn(label: Text('Intervalo')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acções')),
        ],
        rowCount: plans.length,
        rowBuilder: (context, index) {
          final plan = plans[index];
          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(plan.name)),
                    if (plan.isEnterprise) ...[
                      const SizedBox(width: 8),
                      EnterpriseStatusChip(
                        label: 'Enterprise',
                        color: context.pharmaTokens.posInfo,
                      ),
                    ],
                  ],
                ),
              ),
              DataCell(Text(plan.slug)),
              DataCell(Text(currency.format(plan.monthlyPrice))),
              DataCell(Text('${plan.includedBranches}')),
              DataCell(Text(currency.format(plan.extraBranchPrice))),
              DataCell(Text('${plan.trialDays}d')),
              DataCell(
                Text(
                  plan.billingIntervalMonths == 1
                      ? '1 mês'
                      : '${plan.billingIntervalMonths} meses',
                ),
              ),
              DataCell(
                EnterpriseStatusChip(
                  label: plan.active ? 'Activo' : 'Inactivo',
                  color: plan.active
                      ? context.pharmaTokens.posSuccess
                      : context.pharmaTokens.textMuted,
                ),
              ),
              DataCell(_PlanActionsMenu(plan: plan, busy: busy)),
            ],
          );
        },
        pagination: totalCount != null
            ? EnterprisePagination(
                page: page,
                pageSize: pageSize,
                totalCount: totalCount,
                isBusy: isLoading,
                itemLabel: 'planos',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Pesquisar plano ou slug…',
          enabled: !isLoading,
          isLoading: isLoading,
          hasFilters: false,
          showFiltersButton: false,
          onSearchSubmitted: notifier.setSearch,
          onOpenFilters: () {},
        ),
        itemCount: plans.length,
        hasMore: hasMore,
        isLoading: isLoading,
        emptyMessage: 'Sem planos.',
        onLoadMore:
            hasMore && !isLoading ? () => notifier.goToPage(page + 1) : null,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Column(
            children: [
              if (index > 0) const EnterpriseListDivider(),
              EnterpriseListCard(
                title: plan.name,
                subtitle: plan.slug,
                chip: EnterpriseStatusChip(
                  label: plan.active ? 'Activo' : 'Inactivo',
                  color: plan.active
                      ? context.pharmaTokens.posSuccess
                      : context.pharmaTokens.textMuted,
                ),
                actions: _PlanActionsMenu(plan: plan, busy: busy),
                metadata: [
                  EnterpriseListCardMeta(
                    label: currency.format(plan.monthlyPrice),
                    emphasized: true,
                  ),
                  EnterpriseListCardMeta(
                    label: '${plan.includedBranches} filiais · trial ${plan.trialDays}d',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createOrEdit(
    BuildContext context,
    WidgetRef ref, {
    PlatformPlan? plan,
  }) async {
    final payload = await showPlanFormSideSheet(context, plan: plan);
    if (payload == null || !context.mounted) return;
    try {
      final notifier = ref.read(platformBillingActionsProvider.notifier);
      if (plan == null) {
        await notifier.createPlan(payload);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Plano criado.');
      } else {
        await notifier.updatePlan(planId: plan.id, payload: payload);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Plano actualizado.');
      }
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, 'Erro: $e');
    }
  }
}

enum _PlanAction { edit, activate, deactivate }

class _PlanActionsMenu extends ConsumerWidget {
  const _PlanActionsMenu({required this.plan, required this.busy});

  final PlatformPlan plan;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnterpriseActionsMenuButton<_PlanAction>(
      enabled: !busy,
      items: [
        const EnterpriseDropdownItem(
          value: _PlanAction.edit,
          label: 'Editar',
          icon: Icons.edit_outlined,
        ),
        if (plan.active)
          const EnterpriseDropdownItem(
            value: _PlanAction.deactivate,
            label: 'Desactivar',
            icon: Icons.block_outlined,
            destructive: true,
          )
        else
          const EnterpriseDropdownItem(
            value: _PlanAction.activate,
            label: 'Activar',
            icon: Icons.check_circle_outline,
          ),
      ],
      onSelected: (action) async {
        final notifier = ref.read(platformBillingActionsProvider.notifier);
        try {
          switch (action) {
            case _PlanAction.edit:
              final payload =
                  await showPlanFormSideSheet(context, plan: plan);
              if (payload == null || !context.mounted) return;
              await notifier.updatePlan(planId: plan.id, payload: payload);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Plano actualizado.');
            case _PlanAction.activate:
              await notifier.setPlanActive(planId: plan.id, active: true);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Plano activado.');
            case _PlanAction.deactivate:
              final ok = await PharmaFeedback.confirm(
                context: context,
                title: 'Desactivar plano',
                message: 'Desactivar "${plan.name}"?',
                confirmText: 'Desactivar',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await notifier.setPlanActive(planId: plan.id, active: false);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Plano desactivado.');
          }
        } catch (e) {
          if (!context.mounted) return;
          PharmaFeedback.error(context, 'Erro: $e');
        }
      },
    );
  }
}
