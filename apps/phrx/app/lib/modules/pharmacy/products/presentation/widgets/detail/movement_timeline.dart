import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/extensions.dart';

/// Timeline de movimentos de stock.
class MovementTimeline extends StatelessWidget {
  const MovementTimeline({
    super.key,
    required this.movimentos,
    this.emptyMessage = 'Sem movimentos',
  });

  final List<Map<String, dynamic>> movimentos;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (movimentos.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: context.pharmaTokens.textMuted,
              ),
        ),
      );
    }

    final s = context.spacing;

    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemCount: movimentos.length,
      separatorBuilder: (_, _) => SizedBox(height: s.md),
      itemBuilder: (context, index) {
        return _MovementTimelineEntry(
          movimento: movimentos[index],
          isLast: index == movimentos.length - 1,
        );
      },
    );
  }
}

class _MovementTimelineEntry extends StatelessWidget {
  const _MovementTimelineEntry({
    required this.movimento,
    required this.isLast,
  });

  final Map<String, dynamic> movimento;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final data = _formatDate(movimento['createdAt']);
    final tipo = movimento['tipoLabel']?.toString() ??
        movimento['tipo']?.toString() ??
        'Movimento';
    final quantidade = movimento['quantidade']?.toString() ?? '—';
    final utilizador = movimento['user']?['nome']?.toString() ??
        movimento['userName']?.toString() ??
        movimento['utilizador']?.toString() ??
        'Sistema';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: t.brandBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: s.xs),
                      color: t.border.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(t.radiusMd),
              child: Padding(
                padding: EdgeInsets.all(s.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tipo,
                          style: Theme.of(context).textTheme.erpLabel.copyWith(
                                color: t.textPrimary,
                              ),
                        ),
                        Text(
                          data,
                          style: Theme.of(context).textTheme.erpCaption.copyWith(
                                color: t.textMuted,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      'Quantidade: $quantidade',
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.textPrimary,
                          ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      utilizador,
                      style: Theme.of(context).textTheme.erpCaption.copyWith(
                            color: t.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '—';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }
}
