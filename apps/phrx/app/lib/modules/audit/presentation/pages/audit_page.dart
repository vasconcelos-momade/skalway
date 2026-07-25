import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/audit_providers.dart';
import '../widgets/audit_report_exports.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditDashboardProvider);
    final notifier = ref.read(auditDashboardProvider.notifier);
    final dash = state.dashboard;

    return EnterpriseModuleHub(
      title: 'Auditoria',
      subtitle: 'Trilho imutável de operações, permissões e eventos críticos.',
      tag: 'Auditoria',
      actions: [
        ...auditReportActions(
          ref: ref,
          enabled: !state.isBusy,
          path: ReportPaths.auditDashboard,
          queryParameters: const {},
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutePaths.auditTimeline),
          icon: const Icon(Icons.timeline),
          label: const Text('Cronologia'),
        ),
      ],
      kpis: [
        EnterpriseStatCard(
          title: 'Logs totais',
          value: '${dash.totalLogs}',
          icon: Icons.storage_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Últimas 24h',
          value: '${dash.logsLast24h}',
          icon: Icons.schedule,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Eventos críticos (7d)',
          value: '${dash.criticalEventsLast7d}',
          icon: Icons.warning_amber_outlined,
          accent: StatCardAccent.danger,
        ),
        EnterpriseStatCard(
          title: 'Alterações permissões',
          value: '${dash.permissionChangesLast7d}',
          icon: Icons.vpn_key_outlined,
          accent: StatCardAccent.warning,
        ),
      ],
      child: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuditDashboardState state,
    AuditDashboardController notifier,
  ) {
    if (state.viewState == AuditViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == AuditViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar auditoria',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.load,
        icon: Icons.history,
      );
    }

    final events = state.dashboard.recentEvents;
    if (events.isEmpty) {
      return const ModuleEmptyState(
        title: 'Sem eventos recentes',
        subtitle: 'Não existem eventos de negócio registados.',
      );
    }

    final s = context.spacing;

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        if (isMobile) {
          return EnterpriseMobileScrollList(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return EnterpriseListCard(
                leading: Icons.bolt,
                title: '${e.type} • ${e.entity}',
                subtitle: e.entityId != null ? '#${e.entityId}' : null,
                metadata: [
                  EnterpriseListCardMeta(
                    label: '${e.userName ?? 'Sistema'} • ${_dateTime.format(e.createdAt)}',
                  ),
                ],
              );
            },
            stickyHeader: Padding(
              padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.sm),
              child: Text(
                'Eventos recentes',
                style: Theme.of(context).textTheme.erpSectionTitle.copyWith(
                      color: context.pharmaTokens.textPrimary,
                    ),
              ),
            ),
            hasMore: false,
            isLoading: false,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eventos recentes',
              style: Theme.of(context).textTheme.erpSectionTitle.copyWith(
                    color: context.pharmaTokens.textPrimary,
                  ),
            ),
            SizedBox(height: s.sm),
            Expanded(
              child: EnterpriseDataTable(
                adaptive: false,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('TIPO')),
                  DataColumn(label: Text('ENTIDADE')),
                  DataColumn(label: Text('UTILIZADOR')),
                  DataColumn(label: Text('DATA')),
                  DataColumn(label: Text('ID')),
                ],
                rowCount: events.length,
                rowBuilder: (context, index) {
                  final e = events[index];
                  return DataRow(
                    cells: [
                      DataCell(Text(e.type)),
                      DataCell(Text(e.entity)),
                      DataCell(Text(e.userName ?? 'Sistema')),
                      DataCell(Text(_dateTime.format(e.createdAt))),
                      DataCell(Text(e.entityId ?? '—')),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
