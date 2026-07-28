import 'package:flutter/material.dart';

import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';

enum EnterpriseKpiTrend { positive, negative, neutral }

enum EnterpriseKpiState { loading, error, empty, data }

class EnterpriseKpiCard extends StatelessWidget {
  const EnterpriseKpiCard({
    super.key,
    required this.title,
    this.value,
    this.unit,
    required this.icon,
    this.percentage,
    this.trend = EnterpriseKpiTrend.neutral,
    this.description,
    this.state = EnterpriseKpiState.data,
    this.onTap,
  });

  final String title;
  final String? value;
  final String? unit;
  final IconData icon;
  final String? percentage;
  final EnterpriseKpiTrend trend;
  final String? description;
  final EnterpriseKpiState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = context.typography;
    final s = context.spacing;

    if (state == EnterpriseKpiState.loading) {
      return PharmaSurface(
        padding: EdgeInsets.all(s.md),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state == EnterpriseKpiState.error) {
      return PharmaSurface(
        padding: EdgeInsets.all(s.md),
        child: Center(
          child: Text(
            'Erro ao carregar',
            style: textTheme.erpBody.copyWith(color: t.posDanger),
          ),
        ),
      );
    }

    if (state == EnterpriseKpiState.empty) {
      return PharmaSurface(
        padding: EdgeInsets.all(s.md),
        child: Center(
          child: Text(
            'Sem dados',
            style: textTheme.erpBody.copyWith(color: t.textMuted),
          ),
        ),
      );
    }

    final (Color trendColor, Color bgTrendColor, IconData trendIcon) = switch (trend) {
      EnterpriseKpiTrend.positive => (t.brandGreen, t.brandGreen.withValues(alpha: 0.1), Icons.trending_up),
      EnterpriseKpiTrend.negative => (t.posDanger, t.posDanger.withValues(alpha: 0.1), Icons.trending_down),
      EnterpriseKpiTrend.neutral => (t.textSecondary, t.textMuted.withValues(alpha: 0.12), Icons.trending_flat),
    };

    return PharmaSurface(
      padding: EdgeInsets.all(s.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.erpCaption.copyWith(
                    color: t.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(s.xs),
                decoration: BoxDecoration(
                  color: bgTrendColor,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                ),
                child: Icon(icon, size: t.iconSm, color: trendColor),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value ?? '-',
                style: textTheme.erpSectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              if (unit != null) ...[
                SizedBox(width: s.xxs),
                Text(
                  unit!,
                  style: textTheme.erpBody.copyWith(color: t.textMuted),
                ),
              ],
            ],
          ),
          if (percentage != null || description != null) ...[
            SizedBox(height: s.sm),
            Row(
              children: [
                if (percentage != null) ...[
                  Icon(trendIcon, size: t.iconSm, color: trendColor),
                  SizedBox(width: s.xxs),
                  Text(
                    percentage!,
                    style: textTheme.erpCaption.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: s.sm),
                ],
                if (description != null)
                  Expanded(
                    child: Text(
                      description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
