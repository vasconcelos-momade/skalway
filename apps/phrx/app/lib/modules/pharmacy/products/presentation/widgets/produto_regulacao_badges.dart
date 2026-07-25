import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/product.dart';
import '../../domain/produto_dispensacao.dart';

class ProdutoRegulacaoBadges extends StatelessWidget {
  const ProdutoRegulacaoBadges({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final badges = <Widget>[];

    if (_isMedicamento(product)) {
      badges.add(_badge('Medicamento', t.brandBlue));
    }
    if (product.antimicrobiano) {
      badges.add(_badge('Antimicrobiano', t.posWarning));
    }
    if (product.requiresPsychotropicBook ||
        product.tipoDispensacao == 'RECEITA_ESPECIAL' ||
        product.tipoDispensacao == 'PSICOTROPICO' ||
        product.tipoDispensacao == 'NARCOTICO') {
      badges.add(_badge('Psicotrópico', t.brandBlue));
    }
    if (product.requiresPrescription ||
        product.tipoDispensacao == 'RECEITA_NORMAL' ||
        product.tipoDispensacao == 'RECEITA_ESPECIAL' ||
        product.tipoDispensacao == 'RECEITA_OBRIGATORIA' ||
        product.tipoDispensacao == 'RECEITA_CONTROLADA') {
      badges.add(_badge('Receita Obrigatória', t.posWarning));
    }

    if (badges.isEmpty) {
      return Text(
        produtoTipoDispensacaoLabel(product.tipoDispensacao),
        style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
      );
    }

    return Wrap(spacing: s.xs, runSpacing: s.xs, children: badges);
  }

  Widget _badge(String label, Color color) {
    return EnterpriseStatusChip(label: label, color: color);
  }

  bool _isMedicamento(Product product) {
    if (product.categoriaCodigoFnm != null &&
        product.categoriaCodigoFnm!.isNotEmpty) {
      return true;
    }
    final nome = product.categoriaNome?.toLowerCase() ?? '';
    return nome.contains('medicament');
  }
}
