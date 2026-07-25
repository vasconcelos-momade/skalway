import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';

class MovimentacoesLoadingSkeleton extends StatelessWidget {
  const MovimentacoesLoadingSkeleton({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = context.pharmaScreen == PharmaScreenSize.mobile;
    final itemCount = isMobile ? 6 : 8;

    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final height = isMobile ? 132.0 : 58.0;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: t.card.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(t.radiusXl),
            border: Border.all(color: t.border.withValues(alpha: 0.35)),
          ),
        );
      },
    );
  }
}

class MovimentacoesErrorState extends StatelessWidget {
  const MovimentacoesErrorState({
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
            Icon(Icons.cloud_off_rounded, size: 48, color: t.posDanger),
            SizedBox(height: s.md),
            Text(
              'Não foi possível carregar movimentos',
              style: Theme.of(
                context,
              ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            ),
            SizedBox(height: s.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
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

class MovimentacoesEmptyState extends StatelessWidget {
  const MovimentacoesEmptyState({super.key, this.onClearFilters});

  final VoidCallback? onClearFilters;

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
            Icon(Icons.swap_horiz_rounded, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              'Nenhum movimento encontrado',
              style: Theme.of(
                context,
              ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            ),
            SizedBox(height: s.xs),
            Text(
              'Ajuste os filtros ou o período para ver entradas, saídas e ajustes.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            if (onClearFilters != null) ...[
              SizedBox(height: s.md),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MovimentacoesInfoBanner extends StatelessWidget {
  const MovimentacoesInfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.posWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.posWarning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: t.posWarning),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.erpCaption),
          ),
        ],
      ),
    );
  }
}
