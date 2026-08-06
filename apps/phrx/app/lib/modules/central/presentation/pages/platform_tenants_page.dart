import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlays.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../core/theme/elevation_tokens.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/create_branch_form_dialog.dart';
import '../widgets/credit_wallet_side_sheet.dart';
import '../widgets/register_tenant_form_dialog.dart';
import '../../../../shared/refresh/page_refresh.dart';

class PlatformTenantsPage extends ConsumerStatefulWidget {
  const PlatformTenantsPage({super.key});

  @override
  ConsumerState<PlatformTenantsPage> createState() =>
      _PlatformTenantsPageState();
}

class _PlatformTenantsPageState extends ConsumerState<PlatformTenantsPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformTenantSummary> _accumulated = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformTenantsProvider);
    final notifier = ref.read(platformTenantsProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    if (_searchCtrl.text != notifier.search) {
      _searchCtrl.value = TextEditingValue(
        text: notifier.search,
        selection: TextSelection.collapsed(offset: notifier.search.length),
      );
    }

    ref.listen(platformTenantsProvider, (previous, next) {
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
          child: Scaffold(
            backgroundColor: context.pharmaTokens.bgPrimary,
            floatingActionButton: isMobile
                ? FloatingActionButton(
                    onPressed: () => _createTenant(context, ref),
                    backgroundColor: context.pharmaTokens.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: Theme.of(context).extension<ElevationTokens>()?.level3 ?? 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.pharmaTokens.radiusLg),
                    ),
                    child: const Icon(Icons.add_rounded),
                  )
                : null,
            body: EnterpriseModuleHub(
              title: 'Subscrição de tenantes',
              subtitle:
                  'Gestão das subscrições, filiais e histórico operacional dos tenants.',
              tag: 'Plataforma',
              actions: isMobile
                  ? null
                  : [
                      FilledButton.icon(
                        onPressed: () => _createTenant(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Novo tenant'),
                      ),
                    ],
              filters: null,
              child: async.when(
              loading: () => _accumulated.isEmpty
                  ? const ModuleLoadingState()
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      tenants: _accumulated,
                      page: pageData?.page ?? notifier.page,
                      pageSize: pageData?.pageSize ?? notifier.pageSize,
                      hasMore: pageData?.hasMore ?? false,
                      totalCount: pageData?.totalCount,
                      isLoading: true,
                      currency: currency,
                      dateFmt: dateFmt,
                      notifier: notifier,
                    ),
              error: (e, _) => _accumulated.isEmpty
                  ? ModuleErrorState(
                      title: 'Erro ao carregar subscrição de tenantes',
                      message: e.toString(),
                      onRetry: () => notifier.refresh(),
                    )
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      tenants: _accumulated,
                      page: notifier.page,
                      pageSize: notifier.pageSize,
                      hasMore: false,
                      totalCount: null,
                      isLoading: false,
                      errorText: e.toString(),
                      currency: currency,
                      dateFmt: dateFmt,
                      notifier: notifier,
                    ),
              data: (page) => _buildBody(
                context,
                isMobile: isMobile,
                tenants: isMobile ? _accumulated : page.items,
                page: page.page,
                pageSize: page.pageSize,
                hasMore: page.hasMore,
                totalCount: page.totalCount,
                isLoading: false,
                currency: currency,
                dateFmt: dateFmt,
                notifier: notifier,
              ),
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
    required List<PlatformTenantSummary> tenants,
    required int page,
    required int pageSize,
    required bool hasMore,
    required int? totalCount,
    required bool isLoading,
    required NumberFormat currency,
    required DateFormat dateFmt,
    required PlatformTenantsNotifier notifier,
    String? errorText,
  }) {
    return EnterpriseAdaptiveListBody(
      isMobile: isMobile,
      isLoading: isLoading,
      errorText: errorText,
      desktopToolbar: null,
      desktopContent: EnterpriseDataTable(
        adaptive: false,
        showCheckboxColumn: false,
        searchController: _searchCtrl,
        searchHint: 'Pesquisar tenant ou empresa…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading,
        errorMessage: errorText,
        errorTitle: 'Erro ao carregar tenants',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Nenhum tenant encontrado.',
        columns: const [
          DataColumn(label: Text('Tenant')),
          DataColumn(label: Text('Plano')),
          DataColumn(label: Text('Preço Base')),
          DataColumn(label: Text('Filiais / Branches')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acções')),
        ],
        rowCount: tenants.length,
        rowBuilder: (context, index) {
          final t = tenants[index];
          return DataRow(
            cells: [
              DataCell(
                _TenantCell(
                  title: t.tenantName,
                  subtitle: t.tenantKey,
                ),
              ),
              DataCell(
                _PlanCell(
                  planName: t.planName,
                  monthlyValue: t.monthlyValue,
                  currency: currency,
                ),
              ),
              DataCell(
                Text(
                  t.monthlyValue == null
                      ? '—'
                      : currency.format(t.monthlyValue),
                ),
              ),
              DataCell(Text('${t.branchCount}')),
              DataCell(
                EnterpriseStatusChip(
                  label: _tenantStatusLabel(t.status),
                  color: _tenantStatusColor(context, t.status),
                ),
              ),
              DataCell(
                _TenantActionsMenuButton(
                  tenant: t,
                  currency: currency,
                  dateFmt: dateFmt,
                ),
              ),
            ],
          );
        },
        pagination: totalCount != null
            ? EnterprisePagination(
                page: page,
                pageSize: pageSize,
                totalCount: totalCount,
                isBusy: isLoading,
                itemLabel: 'tenants',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      desktopPagination: null,
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Pesquisar tenant ou empresa…',
          enabled: !isLoading,
          isLoading: isLoading,
          hasFilters: false,
          showFiltersButton: false,
          onSearchSubmitted: notifier.setSearch,
          onOpenFilters: () {},
        ),
        itemCount: tenants.length,
        hasMore: hasMore,
        isLoading: isLoading,
        emptyMessage: 'Nenhum tenant encontrado.',
        onLoadMore: hasMore && !isLoading
            ? () => notifier.goToPage(page + 1)
            : null,
        itemBuilder: (context, index) {
          final t = tenants[index];
          return EnterpriseListCard(
            title: t.tenantName,
            subtitle: t.tenantKey,
            chip: EnterpriseStatusChip(
              label: _tenantStatusLabel(t.status),
              color: _tenantStatusColor(context, t.status),
            ),
            actions: _TenantActionsMenuButton(
              tenant: t,
              currency: currency,
              dateFmt: dateFmt,
            ),
            trailingMeta: EnterpriseListCardMeta(
              label: '🏢 ${t.branchCount} ${t.branchCount == 1 ? 'filial' : 'filiais'}',
              alignEnd: true,
            ),
            metadata: [
              EnterpriseListCardMeta(label: t.planName ?? '—'),
              EnterpriseListCardMeta(
                label: t.monthlyValue == null
                    ? '—'
                    : currency.format(t.monthlyValue),
                emphasized: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createTenant(BuildContext context, WidgetRef ref) async {
    final result = await showRegisterTenantFormDialog(context);
    if (result == null || !context.mounted) return;

    if (result.created != null) {
      PharmaFeedback.success(context, 'Tenant criado com sucesso.');
      ref.read(platformTenantsProvider.notifier).refresh();
    }
  }
}

class _TenantCell extends StatelessWidget {
  const _TenantCell({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PlanCell extends StatelessWidget {
  const _PlanCell({
    required this.planName,
    required this.monthlyValue,
    required this.currency,
  });

  final String? planName;
  final double? monthlyValue;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            planName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
            ),
          ),
        ),
        if (monthlyValue != null) ...[
          SizedBox(width: context.spacing.xs),
          EnterpriseStatusChip(
            label: currency.format(monthlyValue),
            color: tokens.posInfo,
          ),
        ],
      ],
    );
  }
}

enum _TenantAction {
  moreInfo,
  history,
  addBranch,
  addCredits,
}

class _TenantActionsMenuButton extends StatelessWidget {
  const _TenantActionsMenuButton({
    required this.tenant,
    required this.currency,
    required this.dateFmt,
  });

  final PlatformTenantSummary tenant;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return EnterpriseActionsMenuButton<_TenantAction>(
      tooltip: 'Acções do tenant',
      items: const [
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.moreInfo,
          label: 'Mais informações',
          icon: Icons.info_outline_rounded,
        ),
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.history,
          label: 'Histórico',
          icon: Icons.history_rounded,
        ),
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.addBranch,
          label: '+ Branch / Filial',
          icon: Icons.add_business_outlined,
        ),
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.addCredits,
          label: 'Adicionar Créditos',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case _TenantAction.moreInfo:
            EnterpriseOverlay.show<void>(
              context: context,
              title: const Text('Mais informações'),
              subtitle: '${tenant.tenantName} • ${tenant.tenantKey}',
              icon: Icons.info_outline_rounded,
              body: _TenantMoreInfoSheet(
                tenantId: tenant.id,
                currency: currency,
                dateFmt: dateFmt,
              ),
            );
          case _TenantAction.history:
            EnterpriseOverlay.show<void>(
              context: context,
              title: const Text('Histórico do tenant'),
              subtitle: '${tenant.tenantName} • ${tenant.tenantKey}',
              icon: Icons.history_rounded,
              size: EnterpriseOverlaySize.large,
              desktopSurface: EnterpriseDesktopSurface.sideSheet,
              body: _TenantHistorySheet(
                tenantId: tenant.id,
                dateFmt: DateFormat('dd/MM/yyyy HH:mm'),
              ),
            );
          case _TenantAction.addBranch:
            final created = await showCreateBranchFormDialog(
              context,
              tenantId: tenant.id,
            );
            if (created == null || !context.mounted) return;
            PharmaFeedback.success(
              context,
              'Filial ${created.code} criada. Extras serão cobrados na próxima renovação.',
            );
          case _TenantAction.addCredits:
            final ok = await showCreditWalletSideSheet(
              context,
              tenantId: tenant.id,
              tenantName: tenant.tenantName,
            );
            if (ok && context.mounted) {
              PharmaFeedback.success(context, 'Créditos adicionados.');
            }
        }
      },
    );
  }
}

class _TenantMoreInfoSheet extends ConsumerWidget {
  const _TenantMoreInfoSheet({
    required this.tenantId,
    required this.currency,
    required this.dateFmt,
  });

  final String tenantId;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantDetailProvider(tenantId));

    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro ao carregar o tenant',
        message: e.toString(),
        onRetry: () => invalidateTenantBilling(ref, tenantId),
      ),
      data: (detail) {
        final summary = detail.summary;
        final subscription = detail.subscription;
        final includedBranches = subscription?.includedBranches ?? 0;
        final activeBranches = subscription?.activeBranches ??
            detail.branches.where((branch) => branch.active).length;
        final nextRenewal = subscription?.nextBillingAt == null
            ? '—'
            : dateFmt.format(subscription!.nextBillingAt!.toLocal());
        final lastInvoice = subscription?.lastInvoiceNumber == null
            ? '—'
            : [
                subscription!.lastInvoiceNumber,
                if (subscription.lastInvoiceStatus != null)
                  _tenantStatusLabel(subscription.lastInvoiceStatus!),
                if (subscription.lastInvoiceAmount != null)
                  currency.format(subscription.lastInvoiceAmount),
              ].join(' • ');
        final trialEndsAt = subscription?.trialEndsAt == null
            ? '—'
            : dateFmt.format(subscription!.trialEndsAt!.toLocal());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EnterpriseListCard(
              title: 'Tenant',
              subtitle: summary.tenantName,
              leading: Icons.business_rounded,
            ),
            EnterpriseListCard(
              title: 'Empresa',
              subtitle: summary.tenantName,
              leading: Icons.apartment_rounded,
            ),
            EnterpriseListCard(
              title: 'Plano',
              subtitle: subscription?.planName ?? summary.planName ?? '—',
              leading: Icons.layers_outlined,
            ),
            EnterpriseListCard(
              title: 'Filiais incluídas',
              subtitle: '$includedBranches',
              leading: Icons.store_mall_directory_outlined,
            ),
            EnterpriseListCard(
              title: 'Filiais activas',
              subtitle: '$activeBranches',
              leading: Icons.storefront_outlined,
            ),
            EnterpriseListCard(
              title: 'Próxima renovação',
              subtitle: nextRenewal,
              leading: Icons.event_repeat_rounded,
            ),
            EnterpriseListCard(
              title: 'Última fatura',
              subtitle: lastInvoice,
              leading: Icons.receipt_long_outlined,
            ),
            EnterpriseListCard(
              title: 'Fim do trial',
              subtitle: trialEndsAt,
              leading: Icons.hourglass_bottom_rounded,
              chip: EnterpriseStatusChip(
                label: _tenantStatusLabel(subscription?.status ?? summary.status),
                color: _tenantStatusColor(
                  context,
                  subscription?.status ?? summary.status,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantHistorySheet extends ConsumerWidget {
  const _TenantHistorySheet({
    required this.tenantId,
    required this.dateFmt,
  });

  final String tenantId;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantBranchHistoryProvider(tenantId));

    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 4),
      error: (e, _) => ModuleErrorState(
        title: 'Erro ao carregar histórico',
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(platformTenantBranchHistoryProvider(tenantId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const ModuleEmptyState(
            title: 'Sem histórico disponível para este tenant.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              EnterpriseListCard(
                title: item.branchName ?? 'Filial sem identificação',
                subtitle:
                    '${item.action} • ${dateFmt.format(item.effectiveDate.toLocal())}',
                leading: item.action == 'ADD'
                    ? Icons.add_business_outlined
                    : Icons.history_toggle_off_rounded,
                chip: EnterpriseStatusChip(
                  label: item.action,
                  color: item.action == 'ADD'
                      ? _tenantStatusColor(context, 'active')
                      : _tenantStatusColor(context, 'suspenso'),
                ),
                metadata: [
                  if (item.branchCode != null)
                    EnterpriseListCardMeta(label: 'Código: ${item.branchCode}'),
                  EnterpriseListCardMeta(
                    label:
                        'Utilizador: ${item.createdByName ?? item.createdByEmail ?? '—'}',
                  ),
                  EnterpriseListCardMeta(
                    label: 'Motivo: ${item.reason ?? '—'}',
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

String _tenantStatusLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'trial':
      return 'Trial';
    case 'ativo':
    case 'active':
      return 'Activo';
    case 'suspenso':
    case 'suspended':
      return 'Suspenso';
    case 'expirado':
    case 'expired':
      return 'Expirado';
    case 'cancelado':
      return 'Cancelado';
    case 'grace':
      return 'Período de graça';
    case 'pendente':
      return 'Pendente';
    case 'parcial':
      return 'Parcial';
    case 'pago':
    case 'paga':
      return 'Paga';
    case 'vencido':
    case 'vencida':
      return 'Vencida';
    case 'confirmado':
      return 'Confirmado';
    default:
      return raw.toUpperCase();
  }
}

Color? _tenantStatusColor(BuildContext context, String raw) {
  final tokens = context.pharmaTokens;

  switch (raw.toLowerCase()) {
    case 'trial':
      return tokens.posInfo;
    case 'ativo':
    case 'active':
    case 'pago':
    case 'paga':
    case 'confirmado':
      return tokens.posSuccess;
    case 'grace':
    case 'parcial':
    case 'pendente':
      return tokens.posWarning;
    case 'suspenso':
    case 'expired':
    case 'expirado':
    case 'vencido':
    case 'vencida':
    case 'cancelado':
    case 'falhado':
      return tokens.posDanger;
    default:
      return null;
  }
}
