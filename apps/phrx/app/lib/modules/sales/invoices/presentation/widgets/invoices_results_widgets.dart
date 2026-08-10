import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../domain/entities/invoice_summary.dart';
import 'invoice_formatters.dart';
import 'invoice_status_badge.dart';

class InvoicesResults extends StatelessWidget {
  const InvoicesResults({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
    required this.onPrint,
    this.searchController,
    this.embedded = false,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;
  final TextEditingController? searchController;
  final bool embedded;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards =
            PharmaScreenLayout.isMobile(context) || constraints.maxWidth < 860;
        if (useCards) {
          final list = InvoiceCardList(
            invoices: invoices,
            onView: onView,
            onCancel: onCancel,
            onPrint: onPrint,
            embedded: embedded,
          );
          return Column(
            mainAxisSize: embedded ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (searchController != null) ...[
                _buildSearchField(context),
                SizedBox(height: context.spacing.sm),
              ],
              if (embedded) list else Expanded(child: list),
            ],
          );
        }
        return Column(
          children: [
            if (searchController != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildSearchField(context),
                ),
              ),
              SizedBox(height: context.spacing.sm),
            ],
            Expanded(
              child: InvoiceDesktopTable(
                invoices: invoices,
                onView: onView,
                onCancel: onCancel,
                onPrint: onPrint,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onRetry: onRetry,
                hasActiveFilters: hasActiveFilters,
                onClearFilters: onClearFilters,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final controller = searchController;
    if (controller == null) return const SizedBox.shrink();
    return EnterpriseSearchField(
      controller: controller,
      hintText: 'Pesquisar nº da fatura, cliente ou terminal',
      onChanged: (_) {},
    );
  }
}

class InvoiceCardList extends StatelessWidget {
  const InvoiceCardList({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
    required this.onPrint,
    this.embedded = false,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Text(
          'Nenhum registo encontrado',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: context.pharmaTokens.textMuted,
              ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (context, index) => const EnterpriseListDivider(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return EnterpriseListCard(
          title: invoice.numero,
          subtitle: invoice.cliente?.nome ?? 'Consumidor final',
          chip: InvoiceStatusBadge(status: invoice.estado),
          onTap: () => onView(invoice),
          metadata: [
            EnterpriseListCardMeta(label: formatDateTime(invoice.createdAt)),
            EnterpriseListCardMeta(label: formatMoney(invoice.total)),
            EnterpriseListCardMeta(
              label: invoice.terminal?.codigo ??
                  invoice.terminal?.nome ??
                  'Sem terminal',
            ),
          ],
          actions: EnterpriseActionsMenuButton<String>(
            items: [
              const EnterpriseDropdownItem(
                value: 'view',
                label: 'Ver',
                icon: Icons.visibility_outlined,
              ),
              const EnterpriseDropdownItem(
                value: 'print',
                label: 'Imprimir',
                icon: Icons.print_outlined,
              ),
              if (!invoice.isCancelled)
                const EnterpriseDropdownItem(
                  value: 'cancel',
                  label: 'Cancelar',
                  icon: Icons.block_rounded,
                  destructive: true,
                ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'view':
                  onView(invoice);
                case 'print':
                  onPrint(invoice);
                case 'cancel':
                  onCancel(invoice);
              }
            },
          ),
        );
      },
    );
  }
}

class InvoiceDesktopTable extends StatelessWidget {
  const InvoiceDesktopTable({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
    required this.onPrint,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  static const _columnLabels = [
    'Nº',
    'Cliente',
    'Data',
    'Total',
    'Estado',
    'Ações',
  ];

  EnterpriseTableStatus get _status {
    if (isLoading && invoices.isEmpty) return EnterpriseTableStatus.loading;
    if (errorMessage != null && invoices.isEmpty) {
      return EnterpriseTableStatus.error;
    }
    if (invoices.isEmpty) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      status: _status,
      isLoading: isLoading,
      errorMessage: errorMessage,
      errorTitle: 'Falha ao carregar faturas',
      onRetry: onRetry,
      emptyTitle: 'Nenhum registo encontrado',
      emptyMessage: 'Nenhum registo encontrado',
      hasActiveFilters: hasActiveFilters,
      onClearFilters: onClearFilters,
      dataRowMinHeight: 54,
      dataRowMaxHeight: 62,
      columnSpacing: s.xl,
      zebraStripes: true,
      columns: [
        for (final label in _columnLabels)
          enterpriseDataColumn(
            context,
            label,
            numeric: label == 'Total',
          ),
      ],
      rowCount: invoices.length,
      rowBuilder: (context, index) {
        final invoice = invoices[index];
        return DataRow(
          cells: [
            DataCell(TablePrimaryCell(invoice.numero)),
            DataCell(
              TableMetadataCell(
                invoice.cliente?.nome ?? 'Consumidor final',
              ),
            ),
            DataCell(
              TableMetadataCell(formatDateTime(invoice.createdAt)),
            ),
            DataCell(
              TableNumericCell(
                formatMoney(invoice.total),
                color: t.brandGreen,
              ),
            ),
            DataCell(InvoiceStatusBadge(status: invoice.estado)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ver',
                    onPressed: () => onView(invoice),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  IconButton(
                    tooltip: invoice.isCancelled ? 'Já cancelada' : 'Cancelar',
                    onPressed:
                        invoice.isCancelled ? null : () => onCancel(invoice),
                    icon: const Icon(Icons.block_rounded),
                  ),
                  IconButton(
                    tooltip: 'Imprimir',
                    onPressed: () => onPrint(invoice),
                    icon: const Icon(Icons.print_outlined),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
