import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../domain/entities/estoque_item.dart';
import 'estoque_actions_menu.dart';
import 'estoque_badges.dart';

class EstoqueMobileList extends StatelessWidget {
  const EstoqueMobileList({
    super.key,
    required this.items,
    required this.actionLoteId,
    this.fornecedores = const [],
  });

  final List<EstoqueItem> items;
  final String? actionLoteId;
  final List<({String id, String nome})> fornecedores;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: context.spacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return EstoqueMobileCard(
          item: item,
          isBusy: actionLoteId == item.id,
          fornecedores: fornecedores,
        );
      },
    );
  }
}

class EstoqueMobileCard extends StatelessWidget {
  const EstoqueMobileCard({
    super.key,
    required this.item,
    required this.isBusy,
    this.fornecedores = const [],
  });

  final EstoqueItem item;
  final bool isBusy;
  final List<({String id, String nome})> fornecedores;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(t.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.inventory_2_outlined, size: t.iconSm, color: t.textPrimary),
                  SizedBox(width: s.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.produtoDisplayLabel,
                          style: theme.textTheme.erpCardTitle.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((item.produtoNomeGenerico ?? '').isNotEmpty) ...[
                          SizedBox(height: s.xxs),
                          Text(
                            item.produtoNomeGenerico!,
                            style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: s.xxs),
                        Text(
                          'Lote ${item.numeroLote} • ${item.categoriaNome ?? '—'}',
                          style: theme.textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  EstoqueActionsMenu(
                    item: item,
                    isBusy: isBusy,
                    compact: true,
                    fornecedores: fornecedores,
                  ),
                ],
              ),
              SizedBox(height: s.xs),
              Wrap(
                spacing: s.xs,
                runSpacing: s.xxs,
                children: [
                  EstoqueBadges.validade(context, item),
                  EstoqueBadges.stock(context, item),
                ],
              ),
              SizedBox(height: s.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Validade: ${_formatDate(item.dataValidade)}',
                    style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                  Text(
                    'Stock: ${LoteStockUtils.formatDisponivelFromNum(item.quantidadeDisponivel)}',
                    style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                ],
              ),
              SizedBox(height: s.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quarentena: ${LoteStockUtils.formatDisponivelFromNum(item.quantidadeQuarentena)}',
                    style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                  Text(
                    'Incineração: ${LoteStockUtils.formatDisponivelFromNum(item.quantidadeIncinerada)}',
                    style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                ],
              ),
              SizedBox(height: s.xxs),
              Text(
                '${item.fornecedorNome ?? '—'} • Compra ${item.precoCompra} • Venda ${item.precoVenda ?? '—'}',
                style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return _dateFormat.format(value.toLocal());
  }
}
