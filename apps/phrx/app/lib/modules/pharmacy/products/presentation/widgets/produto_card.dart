import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/product.dart';
import 'detail/status_badge.dart';

class ProdutoCard extends StatelessWidget {
  const ProdutoCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAction,
  });

  final Product product;
  final VoidCallback onTap;
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final lowStock = product.estoqueAtual <= product.estoqueMinimo;
    final substancia = product.nomeGenerico?.trim();
    final metadata = <EnterpriseListCardMeta>[
      if (product.dosagem != null && product.dosagem!.trim().isNotEmpty)
        EnterpriseListCardMeta(label: product.dosagem!.trim()),
      EnterpriseListCardMeta(label: product.forma ?? '—'),
    ];

    return EnterpriseListCard(
      title: product.nomeComercial,
      subtitle: substancia != null && substancia.isNotEmpty
          ? 'Nome genérico: $substancia'
          : null,
      chip: StatusBadge(active: product.ativo),
      metadata: metadata,
      trailingMeta: EnterpriseListCardMeta(
        label: 'Stock: ${_formatNumber(product.estoqueAtual)}',
        color: lowStock ? t.posDanger : t.textMuted,
        alignEnd: true,
        emphasized: true,
      ),
      // Para seguir o requisito de interagir apenas via menu de ações,
      // o toque no card não abre mais o painel lateral de detalhes.
      onTap: null,
      actions: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: t.minTouchTarget * 0.6,
          minHeight: t.minTouchTarget * 0.6,
        ),
        icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
        onSelected: onAction,
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
