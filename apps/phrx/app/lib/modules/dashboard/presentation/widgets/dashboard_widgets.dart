import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/table_typography.dart';
import '../../../../shared/widgets/dashboard/enterprise_chart_card.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../domain/models/dashboard_filter_option.dart';
import '../../domain/models/dashboard_paged_table_result.dart';
import '../../domain/utils/dashboard_data_utils.dart';
import 'dashboard_state_widgets.dart';

export '../../domain/models/dashboard_filter_option.dart';
export '../../domain/models/dashboard_paged_table_result.dart';
export '../../domain/utils/dashboard_data_utils.dart';

class DashboardFilterSelect extends StatelessWidget {
  const DashboardFilterSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.emptyLabel = 'Todos',
  });

  final String label;
  final List<DashboardFilterOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return EnterpriseSelectField<String>(
      label: label,
      emptyLabel: emptyLabel,
      value: options.any((option) => option.value == value) ? value : null,
      options: [
        for (final option in options)
          EnterpriseSelectOption<String>(
            value: option.value,
            label: option.label,
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class DashboardTableColumn {
  const DashboardTableColumn({
    required this.label,
    this.sortKey,
  });

  final String label;
  final String? sortKey;
}

/// Altura mínima e máxima recomendadas para a área de gráfico dentro do card.
const double kDashboardChartMinHeight = 220.0;
const double kDashboardChartMaxHeight = 320.0;

/// Alturas enterprise (Power BI / Fiori) por breakpoint.
double dashboardEnterpriseChartHeight(
  BuildContext context, {
  required double desktop,
  double? tablet,
  double? mobile,
}) {
  return switch (PharmaScreenLayout.sizeOf(context)) {
    PharmaScreenSize.desktop => desktop,
    PharmaScreenSize.tablet => tablet ?? (desktop - 40).clamp(220.0, desktop),
    PharmaScreenSize.mobile => mobile ?? (desktop - 60).clamp(200.0, desktop),
  };
}

Widget _dashboardChartEmptyState(
  BuildContext context, {
  String message = 'Sem dados no período',
  String? title,
  String? subtitle,
}) {
  final t = context.pharmaTokens;
  final resolvedTitle = title ?? message;
  final resolvedSubtitle = subtitle;
  return LayoutBuilder(
    builder: (context, constraints) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 28,
                color: t.textMuted.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                resolvedTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.erpBody.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (resolvedSubtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  resolvedSubtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .erpBodySecondary
                      .copyWith(color: t.textMuted),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _dashboardScrollableChart({
  required double minWidth,
  required Widget child,
  bool scrollToEnd = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : minWidth;
      final maxH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
          ? constraints.maxHeight
          : null;
      final contentWidth = math.max(maxW, minWidth);
      final needsHorizontalScroll = contentWidth > maxW + 0.5;

      final chart = SizedBox(
        width: needsHorizontalScroll ? contentWidth : maxW,
        height: maxH,
        child: child,
      );

      if (needsHorizontalScroll) {
        // reverse: mostra primeiro o fim da série (dias recentes com dados).
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: scrollToEnd,
          child: chart,
        );
      }
      return chart;
    },
  );
}

Widget _dashboardChartLegend({
  required List<(String label, Color color)> items,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final legend = Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (label, color) in items)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : double.infinity,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.erpCaption,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: legend,
        ),
      );
    },
  );
}

double _dashboardChartMinWidthForCount(int count, {double perItem = 52}) {
  if (count <= 0) return 280;
  return (count * perItem).clamp(280, 1600).toDouble();
}

Widget _dashboardAxisLabel({
  required BuildContext context,
  required TitleMeta meta,
  required String label,
  double angle = 0,
}) {
  return SideTitleWidget(
    meta: meta,
    space: 8,
    angle: angle,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.erpOverline,
    ),
  );
}

Widget dashboardAsyncBody<T>({
  required AsyncValue<T> async,
  required Widget Function(T data) builder,
  VoidCallback? onRetry,
  int loadingKpiCount = 4,
}) {
  return async.when(
    loading: () => DashboardLoadingState(kpiCount: loadingKpiCount),
    error: (error, _) => DashboardErrorState(
      message: '$error',
      onRetry: onRetry ?? () {},
    ),
    data: builder,
  );
}

Widget dashboardLineChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  String? labelKey,
  Color? color,
  String emptyTitle = 'Nenhuma venda registrada',
  String emptySubtitle =
      'Comece a vender para visualizar a evolução financeira.',
  Widget? headerTrailing,
}) {
  final t = context.pharmaTokens;
  final lineColor = color ?? t.brandGreen;
  final hasActivity = points.any((p) => _dashboardNumeric(p[valueKey]) != 0);
  if (points.isEmpty || !hasActivity) {
    return _dashboardChartEmptyState(
      context,
      title: emptyTitle,
      subtitle: emptySubtitle,
    );
  }

  final spots = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final y = _dashboardNumeric(points[i][valueKey]);
    if (y > maxY) maxY = y;
    spots.add(FlSpot(i.toDouble(), y));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.25;
  final minWidth = labelKey == null
      ? 280.0
      : _dashboardChartMinWidthForCount(points.length, perItem: 56);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (headerTrailing != null) ...[
        Align(alignment: Alignment.centerRight, child: headerTrailing),
        const SizedBox(height: AppSpacing.xs),
      ],
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          scrollToEnd: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                clipData: const FlClipData.none(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: t.border.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => t.card,
                    tooltipBorder: BorderSide(color: t.border),
                    getTooltipItems: (touched) => touched
                        .map(
                          (item) => LineTooltipItem(
                            '${item.y.toStringAsFixed(2)} MZN',
                            Theme.of(context).textTheme.erpCaption.copyWith(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: labelKey == null
                      ? const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        )
                      : AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return DefaultTextStyle(
                                style: Theme.of(context)
                                    .textTheme
                                    .erpBodySecondary
                                    .copyWith(color: t.textMuted),
                                child: _dashboardAxisLabel(
                                  context: context,
                                  meta: meta,
                                  label: dashLabel(points[i][labelKey], max: 8),
                                ),
                              );
                            },
                          ),
                        ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: t.card,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.22),
                          lineColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget dashboardChartCard({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  Widget? action,
}) {
  return EnterpriseChartCard(
    title: title,
    subtitle: subtitle,
    action: action,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    ),
  );
}

Widget dashboardBarChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  required String labelKey,
  Color? color,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final values = points
      .map((point) => (point[valueKey] as num?)?.toDouble() ?? 0)
      .toList(growable: false);
  final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.2;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 74);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: BarChart(
      BarChartData(
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => t.card,
            tooltipBorder: BorderSide(color: t.border),
            getTooltipItem: (group, groupIndex, rodData, rodIndex) {
              return BarTooltipItem(
                '${rodData.toY.toStringAsFixed(2)} MZN',
                Theme.of(context).textTheme.erpCaption.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return DefaultTextStyle(
                  style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
                  child: _dashboardAxisLabel(
                    context: context,
                    meta: meta,
                    label: dashLabel(points[i][labelKey], max: 14),
                    angle: -0.5,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(points.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: 18,
                color: color ?? t.brandBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    ),
  );
}

double _dashboardNumeric(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Barras verticais para séries temporais (receita, vendas, saldo por período).
///
/// Diferencia-se do [dashboardBarChart] categórico: barras mais estreitas,
/// gradiente suave e espaçamento optimizado para datas/meses.
/// Com [allowNegative], o eixo inclui valores abaixo de zero (ex.: saldo).
Widget dashboardTrendBarChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  required String labelKey,
  Color? color,
  Color? negativeColor,
  double barWidth = 14,
  bool allowNegative = false,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final positiveColor = color ?? t.brandGreen;
  final deficitColor = negativeColor ?? t.posDanger;
  final values = points
      .map((point) => _dashboardNumeric(point[valueKey]))
      .toList(growable: false);

  var maxY = 0.0;
  var minY = 0.0;
  for (final value in values) {
    if (value > maxY) maxY = value;
    if (allowNegative && value < minY) minY = value;
  }
  final chartMax = maxY > 0
      ? maxY * 1.15
      : (minY < 0 ? (-minY * 0.08).clamp(1.0, double.infinity) : 1.0);
  final chartMin = allowNegative && minY < 0 ? minY * 1.15 : 0.0;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 52);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: BarChart(
      BarChartData(
        minY: chartMin,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return DefaultTextStyle(
                  style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                        color: t.textMuted,
                      ),
                  child: _dashboardAxisLabel(
                    context: context,
                    meta: meta,
                    label: dashLabel(points[i][labelKey], max: 10),
                    angle: points.length > 8 ? -0.45 : 0,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(points.length, (i) {
          final value = values[i];
          final isNegative = value < 0;
          final barColor = isNegative ? deficitColor : positiveColor;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: value,
                width: barWidth,
                gradient: LinearGradient(
                  begin: isNegative ? Alignment.topCenter : Alignment.bottomCenter,
                  end: isNegative ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: [
                    barColor.withValues(alpha: 0.45),
                    barColor,
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: isNegative ? Radius.zero : const Radius.circular(6),
                  bottom: isNegative ? const Radius.circular(6) : Radius.zero,
                ),
              ),
            ],
          );
        }),
      ),
    ),
  );
}

/// Barras agrupadas para séries temporais com receitas e despesas.
Widget dashboardDualTrendBarChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String labelKey,
  String receitasKey = 'receitas',
  String despesasKey = 'despesas',
  Color? receitasColor,
  Color? despesasColor,
  double barWidth = 10,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final incomeColor = receitasColor ?? t.brandGreen;
  final expenseColor = despesasColor ?? t.brandBlue;
  final receitas = points
      .map((point) => (point[receitasKey] as num?)?.toDouble() ?? 0)
      .toList(growable: false);
  final despesas = points
      .map((point) => (point[despesasKey] as num?)?.toDouble() ?? 0)
      .toList(growable: false);
  final maxY = [
    ...receitas,
    ...despesas,
  ].fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 72);

  BarChartRodData rod({
    required double value,
    required Color baseColor,
  }) {
    return BarChartRodData(
      toY: value,
      width: barWidth,
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          baseColor.withValues(alpha: 0.45),
          baseColor,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          child: BarChart(
            BarChartData(
              maxY: chartMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: t.border.withValues(alpha: 0.22),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return DefaultTextStyle(
                        style: Theme.of(context)
                            .textTheme
                            .erpBodySecondary
                            .copyWith(color: t.textMuted),
                        child: _dashboardAxisLabel(
                          context: context,
                          meta: meta,
                          label: dashLabel(points[i][labelKey], max: 10),
                          angle: points.length > 8 ? -0.45 : 0,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(points.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    rod(value: receitas[i], baseColor: incomeColor),
                    rod(value: despesas[i], baseColor: expenseColor),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _dashboardChartLegend(
        items: [
          ('Receitas', incomeColor),
          ('Despesas', expenseColor),
        ],
      ),
    ],
  );
}

class DashboardLineSeries {
  const DashboardLineSeries({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}

bool _dashboardSeriesHasActivity(
  List<Map<String, dynamic>> points,
  List<String> keys,
) {
  for (final point in points) {
    for (final key in keys) {
      if (_dashboardNumeric(point[key]) != 0) return true;
    }
  }
  return false;
}

Widget dashboardMultiLineChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String labelKey,
  required List<DashboardLineSeries> series,
  bool fillFirstSeries = false,
  String emptyTitle = 'Nenhuma venda registrada',
  String emptySubtitle =
      'Comece a vender para visualizar a evolução financeira.',
}) {
  final t = context.pharmaTokens;
  final seriesKeys = series.map((s) => s.key).toList(growable: false);
  if (points.isEmpty ||
      series.isEmpty ||
      !_dashboardSeriesHasActivity(points, seriesKeys)) {
    return _dashboardChartEmptyState(
      context,
      title: emptyTitle,
      subtitle: emptySubtitle,
    );
  }

  final lineData = <LineChartBarData>[];
  var maxY = 0.0;
  var minY = 0.0;

  for (var s = 0; s < series.length; s++) {
    final config = series[s];
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final y = _dashboardNumeric(points[i][config.key]);
      if (y > maxY) maxY = y;
      if (y < minY) minY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }
    lineData.add(
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.28,
        color: config.color,
        barWidth: s == 0 ? 3 : 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: config.color,
            strokeWidth: 2,
            strokeColor: t.card,
          ),
        ),
        belowBarData: BarAreaData(
          show: fillFirstSeries && s == 0,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              config.color.withValues(alpha: 0.22),
              config.color.withValues(alpha: 0.02),
            ],
          ),
        ),
      ),
    );
  }

  // Escala com margem superior para a linha não colar no topo/fundo.
  final chartMax = maxY <= 0 ? 1.0 : maxY * 1.25;
  final chartMin = minY < 0 ? minY * 1.15 : 0.0;
  final labelStep = points.length > 10 ? 2 : 1;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 48);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          scrollToEnd: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: LineChart(
              LineChartData(
                minY: chartMin,
                maxY: chartMax,
                clipData: const FlClipData.none(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: t.border.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => t.card,
                    tooltipBorder: BorderSide(color: t.border),
                    getTooltipItems: (touched) {
                      return touched.map((item) {
                        final seriesIndex = item.barIndex;
                        final label = seriesIndex >= 0 && seriesIndex < series.length
                            ? series[seriesIndex].label
                            : '';
                        return LineTooltipItem(
                          '$label\n${item.y.toStringAsFixed(2)} MZN',
                          Theme.of(context).textTheme.erpCaption.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        );
                      }).toList(growable: false);
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length || i % labelStep != 0) {
                          return const SizedBox.shrink();
                        }
                        return DefaultTextStyle(
                          style: Theme.of(context)
                              .textTheme
                              .erpBodySecondary
                              .copyWith(color: t.textMuted),
                          child: _dashboardAxisLabel(
                            context: context,
                            meta: meta,
                            label: dashLabel(points[i][labelKey], max: 8),
                            angle: points.length > 8 ? -0.4 : 0,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: lineData,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _dashboardChartLegend(
        items: [
          for (final item in series) (item.label, item.color),
        ],
      ),
    ],
  );
}

Widget dashboardGroupedCashFlowChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String labelKey,
  String entradasKey = 'receitas',
  String saidasKey = 'despesas',
  String saldoKey = 'saldo',
}) {
  final t = context.pharmaTokens;
  final hasActivity = _dashboardSeriesHasActivity(points, [
    entradasKey,
    saidasKey,
    saldoKey,
  ]);
  if (points.isEmpty || !hasActivity) {
    return _dashboardChartEmptyState(
      context,
      title: 'Nenhuma movimentação registada',
      subtitle:
          'Registe vendas, despesas ou suprimentos para visualizar o fluxo de caixa.',
    );
  }

  final entradasColor = t.brandGreen;
  final saidasColor = t.posDanger;
  final saldoColor = t.brandBlue;
  final entradas = points
      .map((point) => _dashboardNumeric(point[entradasKey]))
      .toList(growable: false);
  final saidas = points
      .map((point) => _dashboardNumeric(point[saidasKey]))
      .toList(growable: false);
  final saldos = points
      .map((point) => _dashboardNumeric(point[saldoKey]))
      .toList(growable: false);

  var maxY = 0.0;
  var minY = 0.0;
  for (final value in [...entradas, ...saidas, ...saldos]) {
    if (value > maxY) maxY = value;
    if (value < minY) minY = value;
  }

  final chartMax = maxY > 0 ? maxY * 1.20 : 1.0;
  final chartMin = minY < 0 ? minY * 1.15 : 0.0;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 64);
  const barWidth = 18.0;
  final labelStep = points.length > 10 ? 2 : 1;

  BarChartRodData rod({
    required double value,
    required Color color,
  }) {
    return BarChartRodData(
      fromY: 0,
      toY: value,
      width: barWidth,
      color: color,
      borderRadius: BorderRadius.vertical(
        top: value < 0 ? Radius.zero : const Radius.circular(6),
        bottom: value < 0 ? const Radius.circular(6) : Radius.zero,
      ),
    );
  }

  final saldoSpots = <FlSpot>[
    for (var i = 0; i < saldos.length; i++) FlSpot(i.toDouble(), saldos[i]),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          scrollToEnd: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    minY: chartMin,
                    maxY: chartMax,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: t.border.withValues(alpha: 0.22),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => t.card,
                        tooltipBorder: BorderSide(color: t.border),
                        getTooltipItem: (group, groupIndex, rodData, rodIndex) {
                          if (rodIndex != 0) return null;
                          final entrada = entradas[groupIndex];
                          final saida = saidas[groupIndex];
                          final saldo = saldos[groupIndex];
                          return BarTooltipItem(
                            'Entrada:\n${entrada.toStringAsFixed(2)} MZN\n\n'
                            'Saída:\n${saida.toStringAsFixed(2)} MZN\n\n'
                            'Saldo:\n${saldo.toStringAsFixed(2)} MZN',
                            Theme.of(context).textTheme.erpCaption.copyWith(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.left,
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 ||
                                i >= points.length ||
                                i % labelStep != 0) {
                              return const SizedBox.shrink();
                            }
                            return DefaultTextStyle(
                              style: Theme.of(context)
                                  .textTheme
                                  .erpBodySecondary
                                  .copyWith(color: t.textMuted),
                              child: _dashboardAxisLabel(
                                context: context,
                                meta: meta,
                                label: dashLabel(points[i][labelKey], max: 8),
                                angle: points.length > 8 ? -0.4 : 0,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(points.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          rod(value: entradas[i], color: entradasColor),
                          rod(value: saidas[i], color: saidasColor),
                        ],
                      );
                    }),
                  ),
                ),
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      minX: -0.5,
                      maxX: points.length - 0.5,
                      minY: chartMin,
                      maxY: chartMax,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: saldoSpots,
                          isCurved: true,
                          color: saldoColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: saldoColor,
                              strokeWidth: 2,
                              strokeColor: t.card,
                            ),
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _dashboardChartLegend(
        items: [
          ('Entradas', entradasColor),
          ('Saídas', saidasColor),
          ('Saldo', saldoColor),
        ],
      ),
    ],
  );
}

Widget dashboardRankedBarList({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  required String labelKey,
  Color? color,
  String emptyTitle = 'Sem dados no período',
  String? emptySubtitle,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(
      context,
      title: emptyTitle,
      subtitle: emptySubtitle,
    );
  }

  final barColor = color ?? t.brandBlue;
  final values = points
      .map((point) => _dashboardNumeric(point[valueKey]))
      .toList(growable: false);
  final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);

  return LayoutBuilder(
    builder: (context, constraints) {
      return ListView.separated(
        itemCount: points.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final value = values[index];
          final label = DashboardDataUtils.text(points[index][labelKey]);
          final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.erpCaption,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    DashboardDataUtils.money(value),
                    style: Theme.of(context).textTheme.erpCaption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: t.bgSecondary,
                  color: barColor,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Ranking enterprise: produto + quantidade + receita + barra proporcional.
Widget dashboardProductRankingList({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  String emptyTitle = 'Nenhuma venda registrada',
  String emptySubtitle =
      'Comece a vender para visualizar os produtos mais vendidos.',
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(
      context,
      title: emptyTitle,
      subtitle: emptySubtitle,
    );
  }

  final totals = points
      .map((p) => _dashboardNumeric(p['total'] ?? p['quantidade']))
      .toList(growable: false);
  final maxTotal = totals.fold<double>(0, (a, b) => a > b ? a : b);

  return ListView.separated(
    itemCount: points.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (context, index) {
      final row = points[index];
      final name = DashboardDataUtils.productName(row);
      final qty = _dashboardNumeric(row['quantidade']);
      final revenue = _dashboardNumeric(row['total']);
      final ratio = maxTotal <= 0 ? 0.0 : (revenue / maxTotal).clamp(0.0, 1.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.erpOverline.copyWith(
                        color: t.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.erpCaption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qtd: ${qty == qty.roundToDouble() ? qty.toInt() : qty.toStringAsFixed(1)}  ·  Receita: ${revenue.toStringAsFixed(2)} MZN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .erpOverline
                          .copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: t.bgSecondary,
              color: t.brandBlue,
            ),
          ),
        ],
      );
    },
  );
}

/// Ranking de categorias com percentagem (quando há poucas categorias).
Widget dashboardCategoryRankingList({
  required BuildContext context,
  required List<DashboardPieSlice> slices,
}) {
  final t = context.pharmaTokens;
  final total = slices.fold<double>(0, (sum, s) => sum + s.value);
  if (slices.isEmpty || total <= 0) {
    return _dashboardChartEmptyState(
      context,
      title: 'Nenhuma venda por categoria',
      subtitle: 'As vendas por categoria aparecerão aqui.',
    );
  }

  final sorted = [...slices]..sort((a, b) => b.value.compareTo(a.value));

  return ListView.separated(
    itemCount: sorted.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (context, index) {
      final slice = sorted[index];
      final pct = (slice.value / total * 100);
      final ratio = (slice.value / total).clamp(0.0, 1.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slice.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.erpCaption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.erpCaption.copyWith(
                      color: t.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${slice.value.toStringAsFixed(2)} MZN',
            style: Theme.of(context)
                .textTheme
                .erpOverline
                .copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: t.bgSecondary,
              color: slice.color,
            ),
          ),
        ],
      );
    },
  );
}

Widget dashboardDualLineChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final receitas = <FlSpot>[];
  final despesas = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final r = (points[i]['receitas'] as num?)?.toDouble() ?? 0;
    final d = (points[i]['despesas'] as num?)?.toDouble() ?? 0;
    maxY = [maxY, r, d].reduce((a, b) => a > b ? a : b);
    receitas.add(FlSpot(i.toDouble(), r));
    despesas.add(FlSpot(i.toDouble(), d));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;
  final minWidth = _dashboardChartMinWidthForCount(points.length);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          child: ClipRect(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: t.border.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: receitas,
                    isCurved: true,
                    color: t.brandGreen,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: despesas,
                    isCurved: true,
                    color: t.brandBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _dashboardChartLegend(
        items: [
          ('Receitas', t.brandGreen),
          ('Despesas', t.brandBlue),
        ],
      ),
    ],
  );
}

Widget dashboardIndexedBarChart({
  required BuildContext context,
  required List<double> values,
  required List<String> labels,
  List<Color>? barColors,
  double barWidth = 22,
}) {
  final t = context.pharmaTokens;
  if (values.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final palette = barColors ??
      [
        t.posDanger,
        t.posWarning,
        t.brandBlue,
        t.brandGreen,
        t.textSecondary,
      ];
  final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.2;
  final minWidth = _dashboardChartMinWidthForCount(labels.length, perItem: 74);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: BarChart(
      BarChartData(
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return DefaultTextStyle(
                  style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
                  child: _dashboardAxisLabel(
                    context: context,
                    meta: meta,
                    label: labels[i],
                    angle: -0.45,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: barWidth,
                color: palette[i % palette.length],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    ),
  );
}

class DashboardPieSlice {
  const DashboardPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

Widget dashboardPieChart({
  required BuildContext context,
  required List<DashboardPieSlice> slices,
  String emptyLabel = 'OK',
  String emptyTitle = 'Sem dados no período',
  String? emptySubtitle,
}) {
  final t = context.pharmaTokens;
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  final activeSlices = slices.where((slice) => slice.value > 0).toList(growable: false);

  if (total <= 0 && activeSlices.isEmpty) {
    return _dashboardChartEmptyState(
      context,
      title: emptyTitle,
      subtitle: emptySubtitle ?? 'As categorias aparecerão quando houver vendas.',
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
      final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
      final chartDim = math.min(maxW, math.max(maxH - 40, 120));
      final sectionRadius = (chartDim * 0.18).clamp(20.0, 56.0);
      final centerSpaceRadius = (chartDim * 0.12).clamp(12.0, 36.0);

      final sections = total <= 0
          ? [
              PieChartSectionData(
                value: 1,
                color: t.brandGreen.withValues(alpha: 0.35),
                title: emptyLabel,
                radius: sectionRadius,
                titleStyle: Theme.of(context).textTheme.erpOverline.copyWith(
                  color: t.textMuted,
                ),
              ),
            ]
          : activeSlices
              .map(
                (slice) => PieChartSectionData(
                  value: slice.value,
                  color: slice.color,
                  title: '',
                  radius: sectionRadius,
                ),
              )
              .toList(growable: false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: centerSpaceRadius,
                sections: sections,
              ),
            ),
          ),
          if (activeSlices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _dashboardChartLegend(
              items: [
                for (final slice in activeSlices)
                  (slice.label, slice.color),
              ],
            ),
          ],
        ],
      );
    },
  );
}

Widget dashboardSimpleTable({
  required BuildContext context,
  String? title,
  required List<String> headers,
  required List<List<String>> rows,
  List<DashboardTableColumn>? columns,
  int? sortColumnIndex,
  bool sortAscending = true,
  ValueSetter<int>? onSortColumn,
  String emptySubtitle = 'Sem resultados para os filtros selecionados.',
}) {
  final tableColumns = columns ??
      headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(title, style: Theme.of(context).textTheme.erpSectionTitle),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (rows.isEmpty)
        DashboardEmptyState(
          subtitle: emptySubtitle,
        )
      else
        EnterpriseDataTable(
          showCheckboxColumn: false,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: List.generate(tableColumns.length, (index) {
            final column = tableColumns[index];
            return DataColumn(
              label: TableTypography.headerLabel(context, column.label),
              onSort: column.sortKey == null || onSortColumn == null
                  ? null
                  : (_, _) => onSortColumn(index),
            );
          }),
          rowCount: rows.length,
          rowBuilder: (context, index) => DataRow(
            cells: rows[index]
                .map(
                  (cell) => DataCell(
                    TableTypography.cellText(context, cell),
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );
}

class DashboardPaginatedTable extends StatefulWidget {
  const DashboardPaginatedTable({
    super.key,
    required this.title,
    required this.loadPage,
    required this.rowBuilder,
    required this.reloadKey,
    this.headers = const [],
    this.columns,
    this.initialPageSize = PaginationDefaults.pageSize,
    this.initialSortBy,
    this.initialSortDir = 'desc',
    this.emptySubtitle = 'Sem resultados para os filtros selecionados.',
  });

  final String title;
  final List<String> headers;
  final List<DashboardTableColumn>? columns;
  final Future<DashboardPagedTableResult> Function(
    int page,
    int pageSize,
    String? sortBy,
    String sortDir,
  ) loadPage;
  final List<String> Function(Map<String, dynamic> row) rowBuilder;
  final Object reloadKey;
  final int initialPageSize;
  final String? initialSortBy;
  final String initialSortDir;
  final String emptySubtitle;

  @override
  State<DashboardPaginatedTable> createState() => _DashboardPaginatedTableState();
}

class _DashboardPaginatedTableState extends State<DashboardPaginatedTable> {
  DashboardPagedTableResult? _result;
  Object? _error;
  var _page = 1;
  late int _pageSize = widget.initialPageSize;
  late String? _sortBy = widget.initialSortBy;
  late String _sortDir = widget.initialSortDir;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant DashboardPaginatedTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _page = 1;
      _pageSize = widget.initialPageSize;
      _sortBy = widget.initialSortBy;
      _sortDir = widget.initialSortDir;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.loadPage(_page, _pageSize, _sortBy, _sortDir);
      if (!mounted) return;
      setState(() {
        _result = result;
        _page = result.page;
        _pageSize = result.pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _toggleSort(int index) {
    final columns = widget.columns ??
        widget.headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
    if (index < 0 || index >= columns.length) return;
    final sortKey = columns[index].sortKey;
    if (sortKey == null) return;
    setState(() {
      if (_sortBy == sortKey) {
        _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = sortKey;
        _sortDir = 'asc';
      }
      _page = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final tableColumns = widget.columns ??
        widget.headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
    final sortColumnIndex = _sortBy == null
        ? null
        : tableColumns.indexWhere((column) => column.sortKey == _sortBy);

    if (_loading && _result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.erpSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          const DashboardLoadingState(kpiCount: 0),
        ],
      );
    }

    if (_error != null && _result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.erpSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('Não foi possível carregar a tabela: $_error'),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: _fetch, child: const Text('Tentar novamente')),
        ],
      );
    }

    final result = _result ??
        DashboardPagedTableResult(
          items: const [],
          page: _page,
          pageSize: _pageSize,
          hasMore: false,
        );

    final rows = result.items.map(widget.rowBuilder).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
            ),
            if (_sortBy != null)
              Text(
                _sortDir == 'asc' ? 'Ordem ascendente' : 'Ordem descendente',
                style: Theme.of(context).textTheme.erpTableMeta.copyWith(
                      color: t.textMuted,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            '${rows.length} itens nesta página',
            if (result.totalCount != null) '${result.totalCount} no total',
            if (result.totalPages != null) 'página ${result.page} de ${result.totalPages}',
          ].join(' · '),
          style: Theme.of(context).textTheme.erpTableSecondary.copyWith(
                color: t.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading && _result != null)
          const LinearProgressIndicator(minHeight: 2),
        dashboardSimpleTable(
          context: context,
          headers: widget.headers,
          rows: rows,
          columns: tableColumns,
          sortColumnIndex: sortColumnIndex != null && sortColumnIndex >= 0
              ? sortColumnIndex
              : null,
          sortAscending: _sortDir == 'asc',
          onSortColumn: _toggleSort,
          emptySubtitle: widget.emptySubtitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        MovimentacoesPagination(
          page: result.page,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          hasMore: result.hasMore,
          isBusy: _loading,
          onPageChanged: (nextPage) {
            _page = nextPage;
            _fetch();
          },
          onPageSizeChanged: (value) {
            _page = 1;
            _pageSize = value;
            _fetch();
          },
        ),
      ],
    );
  }
}
