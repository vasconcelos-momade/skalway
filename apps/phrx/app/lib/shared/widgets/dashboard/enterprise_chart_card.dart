import 'package:flutter/material.dart';

import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';

enum EnterpriseChartState { loading, error, empty, data }

class EnterpriseChartCard extends StatelessWidget {
  const EnterpriseChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.state = EnterpriseChartState.data,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? action;
  final EnterpriseChartState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = context.typography;
    final s = context.spacing;

    Widget content;
    if (state == EnterpriseChartState.loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state == EnterpriseChartState.error) {
      content = Center(
        child: Text(
          'Erro ao carregar o gráfico',
          style: textTheme.erpBody.copyWith(color: t.posDanger),
        ),
      );
    } else if (state == EnterpriseChartState.empty) {
      content = Center(
        child: Text(
          'Sem dados para o período',
          style: textTheme.erpBody.copyWith(color: t.textMuted),
        ),
      );
    } else {
      content = child;
    }

    return PharmaSurface(
      padding: EdgeInsets.all(s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.erpCardTitle.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: s.xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.erpBody.copyWith(color: t.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[
                SizedBox(width: s.md),
                action!,
              ],
            ],
          ),
          SizedBox(height: s.md),
          Expanded(child: content),
        ],
      ),
    );
  }
}
