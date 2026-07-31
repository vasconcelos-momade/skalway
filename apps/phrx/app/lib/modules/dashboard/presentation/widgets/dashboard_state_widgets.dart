import 'package:flutter/material.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';

class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key, this.kpiCount = 4});

  /// Mantido por compatibilidade de API; ignorado.
  final int kpiCount;

  @override
  Widget build(BuildContext context) => const ModuleLoadingState();
}

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: DesignMetrics.minTouchTarget,
              color: t.posDanger,
            ),
            SizedBox(height: s.md),
            Text(
              'Não foi possível carregar o painel',
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                    color: t.textPrimary,
                  ),
            ),
            SizedBox(height: s.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textMuted,
                  ),
            ),
            SizedBox(height: s.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    this.title,
    this.subtitle = 'Sem resultados para os filtros selecionados.',
    this.icon,
  });

  final String? title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: DesignMetrics.minTouchTarget, color: t.textMuted),
              SizedBox(height: s.sm),
            ],
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                      color: t.textPrimary,
                    ),
              ),
              SizedBox(height: s.xs),
            ],
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
