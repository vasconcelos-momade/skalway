import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../domain/entities/audit_entities.dart';
import '../providers/audit_providers.dart';
import '../widgets/audit_adaptive_list_layout.dart';

class AuditTimelinePage extends ConsumerStatefulWidget {
  const AuditTimelinePage({super.key});

  @override
  ConsumerState<AuditTimelinePage> createState() => _AuditTimelinePageState();
}

class _AuditTimelinePageState extends ConsumerState<AuditTimelinePage> {
  late final TextEditingController _searchController;
  final List<AuditEventSummary> _accumulatedItems = [];
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(auditEventsProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditEventsProvider);
    final notifier = ref.read(auditEventsProvider.notifier);

    ref.listen(auditEventsProvider, (previous, next) {
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

    return EnterpriseModuleHub(
      title: 'Cronologia de eventos',
      subtitle: 'Imutável, assinado e correlacionado a utilizador/terminal.',
      tag: 'Auditoria',
      actions: null,
      filters: null,
      child: AuditAdaptiveListBody<AuditEventSummary>(
        state: state,
        searchController: _searchController,
        searchHint: 'Tipo, entidade...',
        emptyTitle: 'Nenhum evento encontrado',
        emptySubtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros.'
            : 'Ainda não existem eventos registados.',
        errorTitle: 'Falha ao carregar eventos',
        errorIcon: Icons.timeline,
        accumulatedItems: _accumulatedItems,
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
          DataColumn(label: Text('TIPO')),
          DataColumn(label: Text('ENTIDADE')),
          DataColumn(label: Text('UTILIZADOR')),
          DataColumn(label: Text('DATA')),
          DataColumn(label: Text('ID')),
        ],
        rowBuilder: (event) => DataRow(
          cells: [
            DataCell(Text(event.type)),
            DataCell(Text(event.entity)),
            DataCell(Text(event.userName ?? 'Sistema')),
            DataCell(Text(_dateTime.format(event.createdAt))),
            DataCell(Text(event.entityId ?? '—')),
          ],
        ),
        mobileCardBuilder: (event) => EnterpriseListCard(
          leading: Icons.bolt,
          title: '${event.type} • ${event.entity}',
          subtitle: event.entityId != null ? '#${event.entityId}' : null,
          metadata: [
            EnterpriseListCardMeta(
              label: '${event.userName ?? 'Sistema'} • ${_dateTime.format(event.createdAt)}',
            ),
          ],
        ),
        itemId: (event) => event.id,
      ),
    );
  }
}
