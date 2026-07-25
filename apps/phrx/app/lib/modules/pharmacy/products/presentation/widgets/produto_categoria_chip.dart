import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';

class ProdutoCategoriaChip extends StatelessWidget {
  const ProdutoCategoriaChip({
    super.key,
    required this.label,
    this.categoriaCodigo,
    this.compact = true,
  });

  final String label;
  final String? categoriaCodigo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = _colorFor(categoriaCodigo ?? label, t);
    final display = label.replaceAll('_', ' ');

    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      label: Text(display),
      labelStyle: Theme.of(context).textTheme.erpTableSecondary.copyWith(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }

  Color _colorFor(String value, PharmaTokens t) {
    switch (value.toUpperCase()) {
      case 'ANTIMICROBIANOS':
        return t.posWarning;
      case 'SISTEMA_NERVOSO_CENTRAL':
      case 'CARDIOVASCULAR':
        return t.brandBlue;
      case 'DERMATOLOGIA':
      case 'OFTALMOLOGIA':
        return t.posInfo;
      case 'NUTRICAO_VITAMINAS_MINERAIS':
        return t.brandGreen;
      default:
        return t.textSecondary;
    }
  }
}
