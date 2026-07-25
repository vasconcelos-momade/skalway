import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';

class CashflowMobileCard extends StatelessWidget {
  const CashflowMobileCard({
    super.key,
    required this.row,
    required this.formatDateTime,
    required this.formatMoney,
  });

  final Map<String, dynamic> row;
  final String Function(String) formatDateTime;
  final String Function(dynamic) formatMoney;

  void _showDescription(BuildContext context, String descricao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descrição'),
        content: Text(descricao),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final tipo = row['tipo']?.toString() ?? '—';
    final descricao = row['descricao']?.toString() ?? '—';

    Color? chipColor;
    if (tipo.toLowerCase() == 'suprimento' || tipo.toLowerCase() == 'entrada') {
      chipColor = t.posSuccess;
    } else if (tipo.toLowerCase() == 'saida' || tipo.toLowerCase() == 'sangria' || tipo.toLowerCase() == 'saída') {
      chipColor = t.posWarning;
    } else {
      chipColor = t.brandBlue;
    }

    return EnterpriseListCard(
      title: '${formatMoney(row['valor'])} MZN',
      subtitle: formatDateTime(row['data']?.toString() ?? ''),
      chip: EnterpriseStatusChip(
        label: tipo.toUpperCase(),
        color: chipColor,
      ),
      metadata: [
        EnterpriseListCardMeta(
          label: 'Saldo Anterior: ${formatMoney(row['saldoAnterior'])} MZN',
        ),
        EnterpriseListCardMeta(
          label: 'Saldo Final: ${formatMoney(row['saldoFinal'])} MZN',
          emphasized: true,
        ),
      ],
      actions: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: t.textSecondary),
        onSelected: (value) {
          if (value == 'descricao') {
            _showDescription(context, descricao);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'descricao',
            child: Text('Ver Descrição'),
          ),
        ],
      ),
    );
  }
}
