import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../domain/entities/audit_entities.dart';
import '../providers/audit_providers.dart';
import '../widgets/audit_adaptive_list_layout.dart';

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  late final TextEditingController _searchController;
  final List<AuditLogEntry> _accumulatedItems = [];
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(auditLogsProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogsProvider);
    final dashboardState = ref.watch(auditDashboardProvider);
    final notifier = ref.read(auditLogsProvider.notifier);
    final dashboard = dashboardState.dashboard;

    ref.listen(auditLogsProvider, (previous, next) {
      if (previous?.query.page != next.query.page ||
          previous?.query.search != next.query.search ||
          previous?.query.pageSize != next.query.pageSize) {
        if (next.query.page == 1) {
          _accumulatedItems
            ..clear()
            ..addAll(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedItems.any((a) => a.id == e.id))
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (previous?.items != next.items && next.query.page == 1) {
        _accumulatedItems
          ..clear()
          ..addAll(next.items);
      }
    });

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    final kpiCards = [
      EnterpriseStatCard(
        title: 'Total de Logs',
        value: dashboard.totalLogs.toString(),
        icon: Icons.history,
        accent: StatCardAccent.info,
        subtitle: 'Registos capturados',
        density: StatCardDensity.compact,
      ),
      EnterpriseStatCard(
        title: 'Últimas 24h',
        value: dashboard.logsLast24h.toString(),
        icon: Icons.schedule,
        accent: StatCardAccent.positive,
        subtitle: 'Actividade recente',
        density: StatCardDensity.compact,
      ),
      EnterpriseStatCard(
        title: 'Eventos Críticos',
        value: dashboard.criticalEventsLast7d.toString(),
        icon: Icons.warning_amber_rounded,
        accent: StatCardAccent.warning,
        subtitle: 'Últimos 7 dias',
        density: StatCardDensity.compact,
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          title: 'Logs',
          subtitle:
              'Registo imutável de alterações com encadeamento criptográfico.',
          tag: 'Auditoria',
          actions: null,
          filters: null,
          mobileKpisHorizontalScroll: true,
          kpis: isMobile ? null : kpiCards,
          child: AuditAdaptiveListBody<AuditLogEntry>(
            state: state,
            searchController: _searchController,
            searchHint: 'Acção, entidade...',
            emptyTitle: 'Nenhum log encontrado',
            emptySubtitle: state.query.hasFilters
                ? 'Tenta limpar os filtros.'
                : 'Ainda não existem registos de auditoria.',
            errorTitle: 'Falha ao carregar logs',
            errorIcon: Icons.receipt_long,
            accumulatedItems: _accumulatedItems,
            kpis: isMobile ? kpiCards : null,
            onSearchChanged: notifier.onSearchChanged,
            onClearFilters: notifier.clearFilters,
            onRefresh: notifier.refresh,
            onGoToPage: notifier.goToPage,
            onPageSizeChanged: notifier.setPageSize,
            headerActions: [
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : notifier.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
            columns: const [
              DataColumn(label: Text('ACÇÃO')),
              DataColumn(label: Text('ENTIDADE')),
              DataColumn(label: Text('UTILIZADOR')),
              DataColumn(label: Text('DATA')),
              DataColumn(label: Text('ID')),
            ],
            rowBuilder: (log) => DataRow(
              cells: [
                DataCell(Text(log.action)),
                DataCell(Text(log.entity)),
                DataCell(Text(log.userName ?? 'Sistema')),
                DataCell(Text(_dateTime.format(log.createdAt))),
                DataCell(Text(log.entityId ?? '—')),
              ],
            ),
            mobileCardBuilder: (log) => EnterpriseListCard(
              leading: Icons.history,
              title: '${log.action} • ${log.entity}',
              subtitle: log.entityId != null ? '#${log.entityId}' : null,
              metadata: [
                EnterpriseListCardMeta(
                  label:
                      '${log.userName ?? 'Sistema'} • ${_dateTime.format(log.createdAt)}',
                ),
              ],
            ),
            itemId: (log) => log.id,
          ),
        );
      },
    );
  }
}
