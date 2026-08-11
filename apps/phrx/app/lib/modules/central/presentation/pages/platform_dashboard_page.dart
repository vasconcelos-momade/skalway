import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/dashboard/enterprise_alert_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/platform_providers.dart';
import '../../../../shared/refresh/page_refresh.dart';

class PlatformDashboardPage extends ConsumerWidget {
  const PlatformDashboardPage({super.key});

  static final _currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformDashboardProvider);

    return PageRefreshBinder(
      onRefresh: () => ref.read(platformDashboardProvider.notifier).refresh(),
      child: EnterpriseModuleHub(
        title: 'Dashboard',
        subtitle: 'Visão executiva da plataforma SaaS.',
        tag: 'Plataforma',
        scrollable: true,
        actions: const [],
        kpis: async.maybeWhen(
          data: (stats) => [
            EnterpriseStatCard(
              title: 'Total Tenantes',
              value: '${stats.totalClients}',
              icon: Icons.business_outlined,
            ),
            EnterpriseStatCard(
              title: 'Ativos',
              value: '${stats.activeClients}',
              icon: Icons.check_circle_outline,
              accent: StatCardAccent.positive,
            ),
            EnterpriseStatCard(
              title: 'Trial',
              value: '${stats.trialClients}',
              icon: Icons.hourglass_empty,
              accent: StatCardAccent.warning,
            ),
            EnterpriseStatCard(
              title: 'Suspensos',
              value: '${stats.suspendedClients}',
              icon: Icons.block_outlined,
              accent: StatCardAccent.danger,
            ),
            EnterpriseStatCard(
              title: 'Receita Mensal',
              value: _currency.format(stats.monthlyRevenue),
              icon: Icons.payments_outlined,
              accent: StatCardAccent.info,
            ),
            EnterpriseStatCard(
              title: 'Filiais',
              value: '${stats.totalBranches}',
              icon: Icons.store_outlined,
            ),
          ],
          orElse: () => null,
        ),
        child: async.when(
          loading: () => const ModuleLoadingState(),
          error: (e, _) => ModuleErrorState(
            title: 'Erro ao carregar',
            message: e.toString(),
            onRetry: () => ref.invalidate(platformDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stats.alerts.isNotEmpty) ...[
                Text(
                  'Alertas',
                  style: Theme.of(context).textTheme.erpSectionTitle,
                ),
                SizedBox(height: context.spacing.sm),
                _PlatformAlertsSection(alerts: stats.alerts),
                SizedBox(height: context.spacing.xl),
              ],
              Text(
                'Últimos tenantes',
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
              SizedBox(height: context.spacing.md),
              EnterpriseDataTable(
                columns: const [
                  DataColumn(label: Text('Empresa')),
                  DataColumn(label: Text('Tenant')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Plano')),
                ],
                rowCount: stats.recentTenants.length,
                rowBuilder: (context, index) {
                  final t = stats.recentTenants[index];
                  return DataRow(
                    onSelectChanged: (_) => context.go(
                      AppRoutePaths.platformTenantDetailPath(t.id),
                    ),
                    cells: [
                      DataCell(Text(t.tenantName)),
                      DataCell(Text(t.tenantName)),
                      DataCell(EnterpriseStatusChip(label: t.status)),
                      DataCell(Text(t.planName ?? '—')),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformAlertsSection extends StatelessWidget {
  const _PlatformAlertsSection({required this.alerts});

  final List<String> alerts;

  static const double _cardWidth = 280;
  static const double _cardHeight = 96;

  EnterpriseAlertSeverity _severityFor(String alert) {
    final lower = alert.toLowerCase();
    if (lower.contains('graça') || lower.contains('suspens')) {
      return EnterpriseAlertSeverity.error;
    }
    if (lower.contains('trial') || lower.contains('expira')) {
      return EnterpriseAlertSeverity.warning;
    }
    return EnterpriseAlertSeverity.info;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      return SizedBox(
        height: _cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: alerts.length,
          separatorBuilder: (_, _) => SizedBox(width: s.sm),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return SizedBox(
              width: _cardWidth,
              height: _cardHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _cardWidth,
                  height: _cardHeight,
                  child: ClipRect(
                    child: EnterpriseAlertCard(
                      title: alert,
                      description: 'Requer atenção na plataforma',
                      severity: _severityFor(alert),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 3
            : width >= 720
                ? 2
                : 1;
        final gap = s.sm;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final alert in alerts)
              SizedBox(
                width: cardWidth,
                height: _cardHeight,
                child: EnterpriseAlertCard(
                  title: alert,
                  description: 'Requer atenção na plataforma',
                  severity: _severityFor(alert),
                ),
              ),
          ],
        );
      },
    );
  }
}
