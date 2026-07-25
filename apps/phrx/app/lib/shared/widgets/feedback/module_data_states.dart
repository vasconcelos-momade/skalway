import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

class ModuleLoadingState extends StatelessWidget {
  const ModuleLoadingState({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (_, _) => Container(
        height: DesignMetrics.topBarCompact,
        decoration: BoxDecoration(
          color: t.card.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(t.radiusXl),
          border: Border.all(color: t.border.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}

class ModuleErrorState extends StatelessWidget {
  const ModuleErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.widths.authCardMax),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: DesignMetrics.feedbackIconSize, color: t.posDanger),
            SizedBox(height: s.md),
            Text(
              title,
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                    color: t.textPrimary,
                  ),
            ),
            SizedBox(height: s.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
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

class ModuleEmptyState extends StatelessWidget {
  const ModuleEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.onClearFilters,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: DesignMetrics.iconMd, color: t.textMuted),
          SizedBox(height: s.md),
          Text(
            title,
            style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                  color: t.textPrimary,
                ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: s.sm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
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
