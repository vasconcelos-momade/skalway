import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/component_theme.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';
import 'pdv_qty_field.dart';

class PdvProductCard extends StatefulWidget {
  const PdvProductCard({
    super.key,
    required this.product,
    required this.canAdd,
    required this.isAdding,
    required this.onAdd,
    this.compactAction = false,
  });

  final Product product;
  final bool canAdd;
  final bool isAdding;
  final void Function(int quantidade) onAdd;
  final bool compactAction;

  @override
  State<PdvProductCard> createState() => _PdvProductCardState();
}

class _PdvProductCardState extends State<PdvProductCard> {
  int _quantidade = 1;

  @override
  void didUpdateWidget(covariant PdvProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _quantidade = 1;
    } else {
      final stock = widget.product.estoqueAtual.toInt();
      if (stock > 0 && _quantidade > stock) {
        _quantidade = stock;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;
    final hasStock = widget.product.estoqueAtual > 0;
    final lowStock =
        widget.product.estoqueAtual <= widget.product.estoqueMinimo;
    final canInteract = widget.canAdd && !widget.isAdding && hasStock;
    final stock = widget.product.estoqueAtual.toInt();
    final dosagem = widget.product.dosagem?.trim();
    final forma = widget.product.forma?.trim();
    final metadataLine =
        'PV ${pdvFormatMoney(widget.product.precoVenda)} • Val. ${pdvFormatDate(widget.product.dataValidade)} • Lote ${widget.product.lote ?? '—'}';
    final titleStyle = textTheme.erpCardTitle.copyWith(color: t.textPrimary);
    final titleDetailStyle = titleStyle.copyWith(
      color: t.textSecondary,
      fontWeight: FontWeight.w400,
    );
    final titleWidget =
        (widget.compactAction &&
            ((dosagem != null && dosagem.isNotEmpty) ||
                (forma != null && forma.isNotEmpty)))
        ? RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: titleStyle,
              children: [
                TextSpan(text: widget.product.nomeComercial),
                if (dosagem != null && dosagem.isNotEmpty) ...[
                  TextSpan(text: ' - ', style: titleDetailStyle),
                  TextSpan(text: dosagem, style: titleDetailStyle),
                ],
                if (forma != null && forma.isNotEmpty) ...[
                  TextSpan(text: ' - ', style: titleDetailStyle),
                  TextSpan(text: forma, style: titleDetailStyle),
                ],
              ],
            ),
          )
        : null;
    final s = context.spacing;
    final Widget actionButton = SizedBox(
      height: widget.compactAction ? t.compactControlHeight : t.controlHeight,
      width: widget.compactAction ? t.compactControlHeight + s.sm : null,
      child: FilledButton(
        style: PharmaComponentTheme.filled(
          t,
          Theme.of(context).colorScheme,
          compact: widget.compactAction,
        ),
        onPressed: canInteract ? () => widget.onAdd(_quantidade) : null,
        child: widget.isAdding
            ? PharmaButtonLoader(color: t.brandBlue)
            : widget.compactAction
                ? const Text('+')
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, size: t.iconSm),
                      SizedBox(width: s.sm),
                      const Text('Adicionar'),
                    ],
                  ),
      ),
    );

    return EnterpriseListCard(
      title: widget.product.nomeComercial,
      titleWidget: titleWidget,
      subtitle: (widget.product.nomeGenerico ?? '').isNotEmpty
          ? widget.product.nomeGenerico
          : null,
      chip: widget.product.requiresPsychotropicBook
          ? EnterpriseStatusChip(
              label: 'Psicotrópico',
              color: t.psychotropic,
            )
          : widget.product.requiresPrescription
              ? EnterpriseStatusChip(
                  label: 'Receita',
                  color: t.posWarning,
                )
              : null,
      metadata: [
        EnterpriseListCardMeta(label: widget.product.categoriaNome ?? '—'),
        EnterpriseListCardMeta(label: metadataLine),
        if (widget.compactAction)
          EnterpriseListCardMeta(
            label: 'Stock: $stock',
            color: lowStock ? t.posDanger : t.textMuted,
          ),
      ],
      trailingMeta: null,
      onTap: canInteract ? () => widget.onAdd(_quantidade) : null,
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PdvQtyField(
            key: ValueKey('card-qty-${widget.product.id}'),
            maxStock: stock,
            value: _quantidade,
            enabled: canInteract,
            compact: widget.compactAction,
            onChanged: (qty) => setState(() => _quantidade = qty),
          ),
          SizedBox(width: s.sm),
          actionButton,
        ],
      ),
    );
  }
}
