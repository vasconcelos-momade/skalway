import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/extensions.dart';
import '../../../domain/entities/product.dart';
import '../produto_categoria_chip.dart';
import '../produto_regulacao_badges.dart';
import 'status_badge.dart';

/// Cabeçalho do detalhe: nome completo, categoria, estado e badges.
class ProductHeader extends StatelessWidget {
  const ProductHeader({
    super.key,
    required this.product,
    this.onClose,
    this.showClose = false,
  });

  final Product product;
  final VoidCallback? onClose;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showClose)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fechar',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ),
          Text(
            product.nomeComercial,
            style: theme.textTheme.erpCardTitle.copyWith(
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProdutoCategoriaChip(
                label: product.categoriaNome ?? '—',
                categoriaCodigo: product.categoriaCodigoFnm,
              ),
              StatusBadge(active: product.ativo),
            ],
          ),
          SizedBox(height: s.sm),
          ProdutoRegulacaoBadges(product: product),
        ],
      ),
    );
  }
}

/// Nome resumido para AppBar (mobile).
String shortProductName(String name, {int maxLength = 28}) {
  final trimmed = name.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength).trim()}…';
}
