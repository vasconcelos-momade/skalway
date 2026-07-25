import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/register_tenant_form_dialog.dart';

class PlatformTenantsPage extends ConsumerStatefulWidget {
  const PlatformTenantsPage({super.key});

  @override
  ConsumerState<PlatformTenantsPage> createState() =>
      _PlatformTenantsPageState();
}

class _PlatformTenantsPageState extends ConsumerState<PlatformTenantsPage> {
  final _searchCtrl = TextEditingController();

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

    return EnterpriseModuleHub(
      title: 'Clientes',
      subtitle: 'Tenants registados na plataforma.',
      tag: 'Plataforma',
      actions: [
        FilledButton.icon(
          onPressed: () => _createTenant(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo cliente'),
        ),
        OutlinedButton.icon(
          onPressed: () => notifier.refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: EnterpriseSearchField(
        controller: _searchCtrl,
        hintText: 'Pesquisar empresa ou tenant…',
        onChanged: notifier.setSearch,
      ),
      child: async.when(
        loading: () => const ModuleLoadingState(),
        error: (e, _) => ModuleErrorState(
          title: 'Erro ao carregar clientes',
          message: e.toString(),
          onRetry: () => ref.invalidate(platformTenantsProvider),
        ),
        data: (tenants) => _TenantsTable(
          tenants: tenants,
          currency: currency,
          onOpen: (id) => context.go(AppRoutePaths.platformTenantDetailPath(id)),
        ),
      ),
    );
  }

  Future<void> _createTenant(BuildContext context, WidgetRef ref) async {
    final result = await showRegisterTenantFormDialog(context);
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(platformBillingActionsProvider.notifier)
          .registerTenant(result.payload);
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Cliente criado com sucesso.');
      ref.read(platformTenantsProvider.notifier).refresh();
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, 'Falha ao criar cliente: $e');
    }
  }
}

class _TenantsTable extends StatelessWidget {
  const _TenantsTable({
    required this.tenants,
    required this.currency,
    required this.onOpen,
  });

  final List<PlatformTenantSummary> tenants;
  final NumberFormat currency;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    if (tenants.isEmpty) {
      return const ModuleEmptyState(title: 'Nenhum cliente encontrado.');
    }

    return EnterpriseDataTable(
      columns: const [
        DataColumn(label: Text('Empresa')),
        DataColumn(label: Text('Tenant')),
        DataColumn(label: Text('Plano')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Filiais')),
        DataColumn(label: Text('Valor Mensal')),
        DataColumn(label: Text('')),
      ],
      rowCount: tenants.length,
      rowBuilder: (context, index) {
        final t = tenants[index];
        return DataRow(
          onSelectChanged: (_) => onOpen(t.id),
          cells: [
            DataCell(Text(t.companyName)),
            DataCell(Text(t.tenantName)),
            DataCell(Text(t.planName ?? '—')),
            DataCell(EnterpriseStatusChip(label: t.status)),
            DataCell(Text('${t.branchCount}')),
            DataCell(Text(
              t.monthlyValue != null ? currency.format(t.monthlyValue) : '—',
            )),
            DataCell(
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onOpen(t.id),
              ),
            ),
          ],
        );
      },
    );
  }
}
