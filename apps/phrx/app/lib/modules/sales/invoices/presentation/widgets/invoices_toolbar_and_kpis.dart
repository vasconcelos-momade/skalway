import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../providers/invoice_list_provider.dart';

class InvoicesToolbarV2 extends ConsumerWidget {
  const InvoicesToolbarV2({
    super.key,
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final InvoiceListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final query = state.query;
    final notifier = ref.read(invoiceListProvider.notifier);

    final searchField = TextField(
      controller: searchController,
      onChanged: notifier.onSearchChanged,
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

    final chips = <Widget>[
      if (query.hasFilters)
        Padding(
          padding: EdgeInsets.only(right: s.sm),
          child: TextButton.icon(
            onPressed: notifier.clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar'),
          ),
        ),
    ];

    if (screen == PharmaScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          if (chips.isNotEmpty) ...[
            SizedBox(height: s.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: searchField,
          ),
        ),
        if (chips.isNotEmpty) ...[
          SizedBox(width: s.md),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 0,
                runSpacing: s.sm,
                children: chips,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class InvoicesKpiGrid extends StatelessWidget {
  const InvoicesKpiGrid({
    super.key,
    required this.totalInvoices,
    required this.paid,
    required this.pending,
    required this.cancelled,
    this.hasFilters = false,
  });

  final int totalInvoices;
  final int paid;
  final int pending;
  final int cancelled;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screen = context.pharmaScreen;
    return LayoutBuilder(
      builder: (context, c) {
        final cross = switch (screen) {
          PharmaScreenSize.mobile => 1,
          PharmaScreenSize.tablet => 2,
          PharmaScreenSize.desktop => 4,
        };
        final aspect = switch (screen) {
          PharmaScreenSize.mobile => 2.35,
          PharmaScreenSize.tablet => 1.7,
          PharmaScreenSize.desktop => 1.45,
        };
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.md,
          mainAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.md,
          childAspectRatio: aspect,
          children: [
            EnterpriseStatCard(
              title: 'Visíveis',
              value: '$totalInvoices',
              subtitle: hasFilters ? 'Com filtros activos' : 'Lista actual',
              icon: Icons.receipt_long_outlined,
              accent: StatCardAccent.info,
            ),
            EnterpriseStatCard(
              title: 'Pagas',
              value: '$paid',
              subtitle: 'Liquidadas no POS',
              icon: Icons.check_circle_outline_rounded,
              accent: StatCardAccent.positive,
            ),
            EnterpriseStatCard(
              title: 'Pendentes',
              value: '$pending',
              subtitle: 'Emitidas/parciais',
              icon: Icons.timelapse_rounded,
              accent: StatCardAccent.warning,
            ),
            EnterpriseStatCard(
              title: 'Canceladas',
              value: '$cancelled',
              subtitle: 'Com reversão aplicada',
              icon: Icons.block_rounded,
              accent: StatCardAccent.danger,
            ),
          ],
        );
      },
    );
  }
}
