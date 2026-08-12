import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../domain/entities/estoque_item.dart';
import 'estoque_lote_actions_helper.dart';
import 'estoque_stock_entry_helper.dart';

class EstoqueActionsMenu extends ConsumerWidget {
  const EstoqueActionsMenu({
    super.key,
    required this.item,
    required this.isBusy,
    this.compact = false,
    this.fornecedores = const [],
  });

  final EstoqueItem item;
  final bool isBusy;
  final bool compact;
  final List<({String id, String nome})> fornecedores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isBusy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final access = ref.watch(sessionAccessProvider);
    final actions = _buildActions(access, item);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return EnterpriseActionsMenuButton<String>(
      compact: compact,
      items: actions,
      onSelected: (action) =>
          _handleAction(context, ref, action, item, fornecedores),
    );
  }

  static List<EnterpriseDropdownItem<String>> _buildActions(
    SessionAccessState access,
    EstoqueItem item,
  ) {
    final entries = <EnterpriseDropdownItem<String>>[];

    void add(String value, String label, IconData icon) {
      entries.add(
        EnterpriseDropdownItem(value: value, label: label, icon: icon),
      );
    }

    if (access.can('LOTES', 'CREATE_LOTE')) {
      add('movimentar', 'Movimentar Stock', Icons.swap_horiz_rounded);
    }
    if (access.can('LOTES', 'UPDATE')) {
      add('editar', 'Editar lote', Icons.edit_outlined);
      add('preco', 'Alterar preço do lote', Icons.price_change_outlined);
      if (item.acoesPermitidas.isNotEmpty) {
        add(
          'sanitaria',
          'Movimentação sanitária',
          Icons.health_and_safety_outlined,
        );
      }
    }
    if (access.can('INVENTARIO', 'ADJUST_STOCK')) {
      add('ajustar', 'Ajustar stock', Icons.tune_outlined);
    }

    return entries;
  }

  static Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    EstoqueItem item,
    List<({String id, String nome})> fornecedores,
  ) async {
    switch (action) {
      case 'movimentar':
      case 'entrada':
        await EstoqueStockEntryHelper.movimentarStock(
          context,
          ref,
          item,
          fornecedores,
        );
      case 'editar':
        await EstoqueLoteActionsHelper.editarLote(context, ref, item);
      case 'ajustar':
        await EstoqueLoteActionsHelper.ajustarStock(context, ref, item);
      case 'preco':
        await EstoqueLoteActionsHelper.alterarPreco(context, ref, item);
      case 'sanitaria':
        await EstoqueLoteActionsHelper.movimentacaoSanitaria(context, ref, item);
    }
  }
}
