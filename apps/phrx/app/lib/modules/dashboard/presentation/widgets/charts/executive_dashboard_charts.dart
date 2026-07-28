import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

abstract final class ExecutiveDashboardCharts {
  ExecutiveDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final fluxoFinanceiro = DashboardDataUtils.compactTimeSeries(
      DashboardDataUtils.list(charts?['fluxoFinanceiro']),
    );
    final receitaMensal = DashboardDataUtils.list(charts?['receitaMensal']);
    final topProdutos = DashboardDataUtils.list(charts?['topProdutos']);
    final topCategorias = DashboardDataUtils.list(charts?['topCategorias']);

    final categoriaSlices = <DashboardPieSlice>[
      for (var i = 0; i < topCategorias.length; i++)
        DashboardPieSlice(
          label: DashboardDataUtils.text(topCategorias[i]['categoria']),
          value: (topCategorias[i]['total'] as num?)?.toDouble() ?? 0,
          color: _palette(t)[i % _palette(t).length],
        ),
    ].where((s) => s.value > 0).toList(growable: false);

    final receitaHeight = dashboardEnterpriseChartHeight(
      context,
      desktop: 280,
      tablet: 240,
      mobile: 220,
    );
    final fluxoHeight = dashboardEnterpriseChartHeight(
      context,
      desktop: 300,
      tablet: 260,
      mobile: 240,
    );
    final sideHeight = dashboardEnterpriseChartHeight(
      context,
      desktop: 300,
      tablet: 280,
      mobile: 260,
    );
    final evolucaoHeight = dashboardEnterpriseChartHeight(
      context,
      desktop: 280,
      tablet: 240,
      mobile: 220,
    );

    final monthDelta = _monthOverMonthDelta(receitaMensal);

    return [
      DashboardChartSlot(
        fullWidth: true,
        fixedHeight: receitaHeight,
        child: dashboardChartCard(
          context: context,
          title: 'Receita × Resultado',
          subtitle: 'Evolução diária de receita e resultado do período',
          child: dashboardMultiLineChart(
            context: context,
            points: fluxoFinanceiro,
            labelKey: 'data',
            fillFirstSeries: true,
            series: [
              DashboardLineSeries(
                key: 'receitas',
                label: 'Receita',
                color: t.brandGreen,
              ),
              DashboardLineSeries(
                key: 'saldo',
                label: 'Resultado',
                color: t.brandBlue,
              ),
            ],
          ),
        ),
      ),
      DashboardChartSlot(
        fixedHeight: fluxoHeight,
        child: dashboardChartCard(
          context: context,
          title: 'Fluxo de caixa',
          subtitle: 'Entradas, saídas e saldo do período',
          child: dashboardGroupedCashFlowChart(
            context: context,
            points: fluxoFinanceiro,
            labelKey: 'data',
          ),
        ),
      ),
      DashboardChartSlot(
        fixedHeight: evolucaoHeight,
        child: dashboardChartCard(
          context: context,
          title: 'Evolução mensal',
          subtitle: 'Receita acumulada por mês',
          action: monthDelta == null
              ? null
              : _MonthDeltaChip(deltaPercent: monthDelta),
          child: dashboardLineChart(
            context: context,
            points: receitaMensal,
            valueKey: 'total',
            labelKey: 'mes',
            color: t.brandGreen,
          ),
        ),
      ),
      DashboardChartSlot(
        fixedHeight: sideHeight,
        child: dashboardChartCard(
          context: context,
          title: 'Top 10 produtos',
          subtitle: 'Quantidade vendida e receita',
          child: dashboardProductRankingList(
            context: context,
            points: topProdutos.take(10).toList(growable: false),
          ),
        ),
      ),
      DashboardChartSlot(
        fixedHeight: sideHeight,
        child: dashboardChartCard(
          context: context,
          title: 'Vendas por categoria',
          subtitle: categoriaSlices.length >= 3
              ? _leaderSubtitle(categoriaSlices)
              : 'Distribuição por categoria FNM',
          child: categoriaSlices.length >= 3
              ? _CategoryDonutWithLeader(slices: categoriaSlices)
              : dashboardCategoryRankingList(
                  context: context,
                  slices: categoriaSlices,
                ),
        ),
      ),
    ];
  }

  static String _leaderSubtitle(List<DashboardPieSlice> slices) {
    if (slices.isEmpty) return 'Distribuição por categoria';
    final sorted = [...slices]..sort((a, b) => b.value.compareTo(a.value));
    final leader = sorted.first;
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final pct = total <= 0 ? 0 : (leader.value / total * 100);
    return 'Líder: ${leader.label} · ${pct.toStringAsFixed(0)}% das vendas';
  }

  static double? _monthOverMonthDelta(List<Map<String, dynamic>> monthly) {
    if (monthly.length < 2) return null;
    final prev = (monthly[monthly.length - 2]['total'] as num?)?.toDouble() ?? 0;
    final curr = (monthly[monthly.length - 1]['total'] as num?)?.toDouble() ?? 0;
    if (prev == 0) return curr == 0 ? 0 : 100;
    return ((curr - prev) / prev) * 100;
  }

  static List<Color> _palette(dynamic t) => [
        t.brandGreen as Color,
        t.brandBlue as Color,
        t.posWarning as Color,
        t.posDanger as Color,
        t.textSecondary as Color,
      ];
}

class _MonthDeltaChip extends StatelessWidget {
  const _MonthDeltaChip({required this.deltaPercent});

  final double deltaPercent;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final positive = deltaPercent >= 0;
    final color = positive ? t.posSuccess : t.posDanger;
    final sign = positive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$sign${deltaPercent.toStringAsFixed(1)}% vs mês anterior',
        style: Theme.of(context).textTheme.erpOverline.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CategoryDonutWithLeader extends StatelessWidget {
  const _CategoryDonutWithLeader({required this.slices});

  final List<DashboardPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final sorted = [...slices]..sort((a, b) => b.value.compareTo(a.value));
    final leader = sorted.first;
    final pct = total <= 0 ? 0.0 : (leader.value / total * 100);
    final isMobile = PharmaScreenLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.bgSecondary,
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoria líder',
                        style: Theme.of(context)
                            .textTheme
                            .erpOverline
                            .copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leader.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.erpCaption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.erpSectionTitle.copyWith(
                        color: t.brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: dashboardPieChart(
            context: context,
            slices: slices,
          ),
        ),
      ],
    );
  }
}
