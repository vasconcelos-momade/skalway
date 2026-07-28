import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventario_provider.dart';
import 'inventory_count_sheet.dart';

Future<void> showInventariadosSheet(BuildContext context) {
  final width = AdaptiveNavigator.widthOf(context);
  final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint
      ? 720.0
      : 560.0;

  return AdaptiveNavigator.openPanel<void>(
    context: context,
    sideSheetWidth: panelWidth,
    routeSettings: const RouteSettings(name: '/inventario/itens'),
    builder: (sheetContext) {
      final body = const _InventariadosBody();
      if (AdaptiveNavigator.isMobile(sheetContext)) {
        return Scaffold(
          appBar: AppBar(title: const Text('Itens Inventariados')),
          body: SafeArea(child: body),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.pharmaTokens.density.lg,
              context.pharmaTokens.density.md,
              context.pharmaTokens.density.sm,
              context.pharmaTokens.density.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Itens Inventariados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.pharmaTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => AdaptiveNavigator.close(sheetContext),
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.pharmaTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: _InventariadosBody()),
        ],
      );
    },
  );
}

class _InventariadosBody extends ConsumerWidget {
  const _InventariadosBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = t.density;
    final state = ref.watch(inventarioProvider);
    final items = state.inventariadosItems;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(s.lg),
          child: Text(
            'Ainda não há itens inventariados.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: t.textMuted,
                ),
          ),
        ),
      );
    }

    Future<void> editItem(InventarioItem item) async {
      final value = await showDialog<double>(
        context: context,
        builder: (dialogContext) => _EditCountDialog(item: item),
      );
      if (value == null) return;
      await ref.read(inventarioProvider.notifier).recordCount(
            item: item,
            estoqueContado: value,
          );
    }

    Future<void> removeItem(InventarioItem item) async {
      final confirmed = await PharmaFeedback.confirm(
        context: context,
        title: 'Remover item',
        message:
            'Remover o lote ${item.numeroLote ?? item.produtoNome} do inventário?',
        confirmText: 'Remover',
        cancelText: 'Cancelar',
        destructive: true,
      );
      if (confirmed != true) return;
      await ref.read(inventarioProvider.notifier).removeItem(item);
    }

    if (isMobile) {
      return ListView.separated(
        padding: EdgeInsets.all(s.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: s.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return EnterpriseListCard(
            title: item.produtoNome,
            subtitle:
                'Lote ${item.numeroLote ?? '—'} · Contado ${formatInventoryQuantity(item.estoqueContado)}',
            chip: EnterpriseStatusChip(
              label: item.hasDivergencia ? 'Divergência' : 'OK',
              color: item.hasDivergencia ? t.posWarning : t.posSuccess,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: state.isBusy ? null : () => editItem(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: state.isBusy ? null : () => removeItem(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.lg),
      child: EnterpriseDataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Produto')),
          DataColumn(label: Text('Lote')),
          DataColumn(label: Text('Validade')),
          DataColumn(label: Text('Stock Sistema')),
          DataColumn(label: Text('Qtd Contada')),
          DataColumn(label: Text('Diferença')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Ações')),
        ],
        rowCount: items.length,
        rowBuilder: (context, index) {
          final item = items[index];
          final validade = item.dataValidade == null
              ? '—'
              : (() {
                  final date = DateTime.tryParse(item.dataValidade!);
                  return date == null
                      ? item.dataValidade!
                      : formatInventoryDate(date);
                })();

          return DataRow(
            cells: [
              DataCell(Text(item.produtoNome)),
              DataCell(Text(item.numeroLote ?? '—')),
              DataCell(Text(validade)),
              DataCell(Text(formatInventoryQuantity(item.estoqueSistema))),
              DataCell(Text(formatInventoryQuantity(item.estoqueContado))),
              DataCell(Text(formatInventoryQuantity(item.divergencia))),
              DataCell(
                EnterpriseStatusChip(
                  label: item.hasDivergencia ? 'Divergência' : 'OK',
                  color: item.hasDivergencia ? t.posWarning : t.posSuccess,
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: state.isBusy ? null : () => editItem(item),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      onPressed: state.isBusy ? null : () => removeItem(item),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditCountDialog extends StatefulWidget {
  const _EditCountDialog({required this.item});

  final InventarioItem item;

  @override
  State<_EditCountDialog> createState() => _EditCountDialogState();
}

class _EditCountDialogState extends State<_EditCountDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatInventoryQuantity(widget.item.estoqueContado),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar contagem'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: 'Unidades Contadas',
          helperText:
              'Stock sistema: ${formatInventoryQuantity(widget.item.estoqueSistema)}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () {
                  final value = double.tryParse(
                    _controller.text.replaceAll(',', '.'),
                  );
                  if (value == null) return;
                  setState(() => _saving = true);
                  Navigator.pop(context, value);
                },
          child: _saving
              ? const PharmaButtonLoader()
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
