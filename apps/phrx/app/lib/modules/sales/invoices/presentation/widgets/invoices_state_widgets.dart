import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../providers/invoice_list_provider.dart';

class InvoicesLoadingSkeleton extends StatelessWidget {
  const InvoicesLoadingSkeleton({super.key, this.embedded = false});

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
        final height = isMobile ? 142.0 : 58.0;
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

class InvoicesInfoBanner extends StatelessWidget {
  const InvoicesInfoBanner({super.key, required this.state});

  final InvoiceListState state;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isWarning = state.errorMessage != null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: isWarning
            ? t.posWarning.withValues(alpha: 0.12)
            : t.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(
          color: isWarning
              ? t.posWarning.withValues(alpha: 0.35)
              : t.brandBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.cloud_off_rounded
                : Icons.history_toggle_off_rounded,
            color: isWarning ? t.posWarning : t.brandBlue,
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              state.errorMessage != null
                  ? 'A mostrar cache em memória. ${state.errorMessage}'
                  : 'A mostrar cache instantânea enquanto a API sincroniza.',
              style: Theme.of(context).textTheme.erpCaption.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoicesErrorState extends StatelessWidget {
  const InvoicesErrorState({
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 42, color: t.posDanger),
            SizedBox(height: s.md),
            Text(
              'Falha ao carregar faturas',
              style: Theme.of(
                context,
              ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            ),
            SizedBox(height: s.sm),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.lg),
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

class InvoicesEmptyState extends StatelessWidget {
  const InvoicesEmptyState({super.key, this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: t.textMuted),
          SizedBox(height: s.md),
          Text(
            'Nenhuma fatura encontrada',
            style: Theme.of(
              context,
            ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.sm),
          Text(
            onClearFilters != null
                ? 'Tenta limpar os filtros para ver mais resultados.'
                : 'Ainda não existem faturas disponíveis para esta unidade.',
            style: Theme.of(
              context,
            ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          ),
          if (onClearFilters != null) ...[
            SizedBox(height: s.lg),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}
