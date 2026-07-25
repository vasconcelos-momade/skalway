import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../domain/entities/estoque_item.dart';

class EstoqueBadges {
  EstoqueBadges._();

  static Widget estadoSanitario(BuildContext context, String? value) {
    final t = context.pharmaTokens;
    final normalized = value?.toUpperCase() ?? '';
    final (label, color) = switch (normalized) {
      'VALIDO' => ('Válido', t.brandGreen),
      'EXPIRADO' => ('Expirado', t.posDanger),
      'RECALL' => ('Recall', t.posWarning),
      'QUARENTENA' => ('Quarentena', t.posWarning),
      _ => ('—', t.textMuted),
    };
    return _badge(context, label, color);
  }

  static Widget disponibilidade(BuildContext context, String? value) {
    final t = context.pharmaTokens;
    final normalized = value?.toUpperCase() ?? '';
    final (label, color) = switch (normalized) {
      'DISPONIVEL' => ('Disponível', t.brandGreen),
      'BLOQUEADO' => ('Bloqueado', t.posWarning),
      'INDISPONIVEL' => ('Indisponível', t.posDanger),
      'RESERVADO' => ('Reservado', t.brandBlue),
      _ => ('—', t.textMuted),
    };
    return _badge(context, label, color);
  }

  static Widget validade(BuildContext context, EstoqueItem item) {
    final t = context.pharmaTokens;
    final indicador = item.indicadorValidade?.toUpperCase();
    final (label, color) = switch (indicador) {
      'EXPIRADO' => ('Expirado', t.posDanger),
      '30_DIAS' => ('A expirar', t.posWarning),
      '60_DIAS' => ('A expirar', t.posWarning),
      _ => ('Normal', t.brandGreen),
    };
    return _badge(context, label, color);
  }

  static Widget stock(BuildContext context, EstoqueItem item) {
    final t = context.pharmaTokens;
    final disponivel = item.quantidadeDisponivel;
    final (label, color) = disponivel <= 0
        ? ('Sem stock', t.posDanger)
        : item.estoqueMinimo > 0 && disponivel <= item.estoqueMinimo
            ? ('Baixo', t.posWarning)
            : ('Normal', t.brandGreen);
    return _badge(context, label, color);
  }

  static Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
      ),
    );
  }
}
