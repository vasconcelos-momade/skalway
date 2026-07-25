import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
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
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;
  final TextEditingController? searchController;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards =
            PharmaScreenLayout.isMobile(context) || constraints.maxWidth < 860;
        if (useCards) {
          return Column(
            children: [
              if (searchController != null) ...[
                _buildSearchField(context),
                SizedBox(height: context.spacing.sm),
              ],
              Expanded(
                child: InvoiceCardList(
                  invoices: invoices,
                  onView: onView,
                  onCancel: onCancel,
                  onPrint: onPrint,
                  embedded: embedded,
                ),
              ),
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
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: InvoiceDesktopTable(
                  invoices: invoices,
                  onView: onView,
                  onCancel: onCancel,
                  onPrint: onPrint,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final t = context.pharmaTokens;
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Pesquisar nº da fatura, cliente ou terminal',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        isDense: true,
      ),
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
    final t = context.pharmaTokens;
    final s = context.spacing;
    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (context, index) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(t.radiusXl),
              onTap: () => onView(invoice),
              child: Padding(
                padding: EdgeInsets.all(s.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.numero,
                            style: TableTypography.primary(context),
                          ),
                        ),
                        InvoiceStatusBadge(status: invoice.estado),
                      ],
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      invoice.cliente?.nome ?? 'Consumidor final',
                      style: Theme.of(context).textTheme.erpBodySecondary
                          .copyWith(color: t.textSecondary),
                    ),
                    SizedBox(height: s.sm),
                    Wrap(
                      spacing: s.sm,
                      runSpacing: s.xs,
                      children: [
                        MetaChip(label: formatDateTime(invoice.createdAt)),
                        MetaChip(label: formatMoney(invoice.total)),
                        MetaChip(
                          label:
                              invoice.terminal?.codigo ??
                              invoice.terminal?.nome ??
                              'Sem terminal',
                        ),
                      ],
                    ),
                    SizedBox(height: s.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onView(invoice),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver'),
                        ),
                        SizedBox(height: s.sm),
                        OutlinedButton.icon(
                          onPressed: () => onPrint(invoice),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Imprimir'),
                        ),
                        SizedBox(height: s.sm),
                        FilledButton.icon(
                          onPressed: invoice.isCancelled
                              ? null
                              : () => onCancel(invoice),
                          icon: const Icon(Icons.block_rounded),
                          label: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: LayoutBuilder(
        builder: (context, c) {
          final dense = c.maxWidth < 1100;
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    t.bgSecondary.withValues(alpha: 0.92),
                  ),
                  dataRowMinHeight: dense ? 48 : 54,
                  dataRowMaxHeight: dense ? 54 : 62,
                  horizontalMargin: dense ? s.md : s.lg,
                  columnSpacing: dense ? s.lg : s.xl,
                  columns: [
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Nº'),
                    ),
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Cliente'),
                    ),
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Data'),
                    ),
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Total'),
                    ),
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Estado'),
                    ),
                    DataColumn(
                      label: TableTypography.headerLabel(context, 'Ações'),
                    ),
                  ],
                  rows: invoices
                      .map((invoice) {
                        return DataRow(
                          cells: [
                            DataCell(
                              TableTypography.cellText(context, invoice.numero),
                            ),
                            DataCell(
                              TableTypography.cellText(
                                context,
                                invoice.cliente?.nome ?? 'Consumidor final',
                              ),
                            ),
                            DataCell(
                              TableTypography.cellText(
                                context,
                                formatDateTime(invoice.createdAt),
                              ),
                            ),
                            DataCell(
                              TableTypography.cellText(
                                context,
                                formatMoney(invoice.total),
                                style: TableTypography.primary(
                                  context,
                                  color: t.brandGreen,
                                ),
                              ),
                            ),
                            DataCell(
                              InvoiceStatusBadge(status: invoice.estado),
                            ),
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
                                    tooltip: invoice.isCancelled
                                        ? 'Já cancelada'
                                        : 'Cancelar',
                                    onPressed: invoice.isCancelled
                                        ? null
                                        : () => onCancel(invoice),
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
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
