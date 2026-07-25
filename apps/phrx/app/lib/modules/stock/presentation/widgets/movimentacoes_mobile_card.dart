import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesMobileCard extends StatelessWidget {
  const MovimentacoesMobileCard({super.key, required this.item});

  final Movimentacao item;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final tipoColor = _tipoColor(t, item.tipo);
    final produtoNome = item.produto?.nome ?? '—';
    final barcode = item.produto?.barcode;
    final produtoLabel = barcode == null || barcode.isEmpty
        ? produtoNome
        : '$produtoNome · $barcode';

    return EnterpriseListCard(
      title: produtoLabel,
      subtitle: _formatDateTime(item.createdAt),
      chip: EnterpriseStatusChip(
        label: item.tipoLabel.toUpperCase(),
        color: tipoColor,
      ),
      metadata: [
        EnterpriseListCardMeta(
          label: 'Qtd: ${_formatQty(item.quantidade)}',
          emphasized: true,
        ),
        EnterpriseListCardMeta(
          label:
              'Stock: ${_formatQty(item.estoqueAnterior)} → ${_formatQty(item.estoqueFinal)}',
        ),
        EnterpriseListCardMeta(
          label:
              'Lote: ${item.lote?.numeroLote ?? '—'} · ${item.origemLabel}',
        ),
        if (item.user?.nome != null)
          EnterpriseListCardMeta(label: 'Utilizador: ${item.user!.nome}'),
      ],
    );
  }

  Color _tipoColor(PharmaTokens t, MovimentacaoTipo? tipo) {
    return switch (tipo) {
      MovimentacaoTipo.entrada => t.brandGreen,
      MovimentacaoTipo.compra => t.brandGreen,
      MovimentacaoTipo.saida => t.posDanger,
      MovimentacaoTipo.ajuste => t.brandBlue,
      MovimentacaoTipo.devolucao => t.posWarning,
      MovimentacaoTipo.quarentena => t.posWarning,
      MovimentacaoTipo.incineracao => t.textMuted,
      null => t.textMuted,
    };
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
