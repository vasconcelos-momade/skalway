import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/theme/design_tokens.dart';
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

    final t = context.pharmaTokens;

    return PopupMenuButton<String>(
      tooltip: 'Acções',
      constraints: compact
          ? BoxConstraints(
              minWidth: t.minTouchTarget * 0.6,
              minHeight: t.minTouchTarget * 0.6,
            )
          : null,
      icon: Icon(
        Icons.more_vert,
        size: compact ? t.iconSm : t.iconMd,
        color: t.textMuted,
      ),
      onSelected: (action) =>
          _handleAction(context, ref, action, item, fornecedores),
      itemBuilder: (context) => actions,
    );
  }

  static List<PopupMenuEntry<String>> _buildActions(
    SessionAccessState access,
    EstoqueItem item,
  ) {
    final entries = <PopupMenuEntry<String>>[];

    void add(String value, String label) {
      entries.add(PopupMenuItem(value: value, child: Text(label)));
    }

    if (access.can('LOTES', 'CREATE_LOTE')) {
      add('entrada', 'Entrada');
    }
    if (access.can('LOTES', 'UPDATE')) {
      add('editar', 'Editar lote');
      add('preco', 'Alterar preço do lote');
      if (item.acoesPermitidas.isNotEmpty) {
        add('sanitaria', 'Movimentação sanitária');
      }
    }
    if (access.can('INVENTARIO', 'ADJUST_STOCK')) {
      add('ajustar', 'Ajustar stock');
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
      case 'entrada':
        await EstoqueStockEntryHelper.entradaCompra(
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
