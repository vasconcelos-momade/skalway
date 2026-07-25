import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../domain/entities/inventario.dart';

class InventoryMobileSummaryBar extends StatelessWidget {
  const InventoryMobileSummaryBar({
    super.key,
    required this.inventory,
    required this.recordedCount,
    required this.onOpen,
  });

  final InventarioDetalhe inventory;
  final int recordedCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      elevation: 2,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      inventory.codigo,
                      style: Theme.of(
                        context,
                      ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                    ),
                    SizedBox(height: s.xxs),
                    Text(
                      '$recordedCount contagem(ns) • ${inventory.itensComDivergencia} divergência(s)',
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onOpen,
                child: const Text('Ver detalhes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
