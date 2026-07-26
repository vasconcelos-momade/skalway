import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/component_theme.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';

class PdvProductCard extends StatelessWidget {
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
  final VoidCallback onAdd;
  final bool compactAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;
    final hasStock = product.estoqueAtual > 0;
    final lowStock = product.estoqueAtual <= product.estoqueMinimo;
    final canInteract = canAdd && !isAdding && hasStock;
    final dosagem = product.dosagem?.trim();
    final forma = product.forma?.trim();
    final metadataLine =
        'PV ${pdvFormatMoney(product.precoVenda)} • Val. ${pdvFormatDate(product.dataValidade)} • Lote ${product.lote ?? '—'}';
    final titleStyle = textTheme.erpCardTitle.copyWith(color: t.textPrimary);
    final titleDetailStyle = titleStyle.copyWith(
      color: t.textSecondary,
      fontWeight: FontWeight.w400,
    );
    final titleWidget =
        (compactAction &&
            ((dosagem != null && dosagem.isNotEmpty) ||
                (forma != null && forma.isNotEmpty)))
        ? RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: titleStyle,
              children: [
                TextSpan(text: product.nomeComercial),
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
      height: compactAction ? t.compactControlHeight : t.controlHeight,
      width: double.infinity,
      child: FilledButton(
        style: PharmaComponentTheme.filled(
          t,
          Theme.of(context).colorScheme,
          compact: compactAction,
        ),
        onPressed: canInteract ? onAdd : null,
        child: isAdding
            ? PharmaButtonLoader(color: t.brandBlue)
            : compactAction
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
      title: product.nomeComercial,
      titleWidget: titleWidget,
      subtitle: (product.nomeGenerico ?? '').isNotEmpty
          ? product.nomeGenerico
          : null,
      chip: product.requiresPsychotropicBook
          ? EnterpriseStatusChip(
              label: 'Psicotrópico',
              color: t.psychotropic,
            )
          : product.requiresPrescription
              ? EnterpriseStatusChip(
                  label: 'Receita',
                  color: t.posWarning,
                )
              : null,
      metadata: [
        EnterpriseListCardMeta(label: product.categoriaNome ?? '—'),
        EnterpriseListCardMeta(label: metadataLine),
      ],
      trailingMeta: compactAction
          ? EnterpriseListCardMeta(
              label: 'Stock: ${product.estoqueAtual.toInt()}',
              color: lowStock ? t.posDanger : t.textMuted,
              alignEnd: true,
              emphasized: true,
            )
          : null,
      onTap: canInteract ? onAdd : null,
      actions: actionButton,
    );
  }
}
