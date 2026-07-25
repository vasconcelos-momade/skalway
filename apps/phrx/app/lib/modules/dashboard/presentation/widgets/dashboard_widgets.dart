import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/pharma_surface.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/table_typography.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../domain/dashboard_query.dart';
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
const double kDashboardChartMinHeight = 240.0;
const double kDashboardChartMaxHeight = 420.0;

Widget _dashboardChartEmptyState(
  BuildContext context, {
  String message = 'Sem dados no período',
}) {
  final t = context.pharmaTokens;
  return LayoutBuilder(
    builder: (context, constraints) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          ),
        ),
      );
    },
  );
}

Widget _dashboardScrollableChart({
  required double minWidth,
  required Widget child,
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final spots = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final y = (points[i][valueKey] as num?)?.toDouble() ?? 0;
    if (y > maxY) maxY = y;
    spots.add(FlSpot(i.toDouble(), y));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;
  final minWidth = labelKey == null
      ? 280.0
      : _dashboardChartMinWidthForCount(points.length);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMax,
          clipData: const FlClipData.none(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: labelKey == null
                ? const AxisTitles(sideTitles: SideTitles(showTitles: false))
                : AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return DefaultTextStyle(
                          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
                          child: _dashboardAxisLabel(
                            context: context,
                            meta: meta,
                            label: dashLabel(points[i][labelKey], max: 10),
                          ),
                        );
                      },
                    ),
                  ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color ?? t.brandGreen,
              barWidth: 2.5,
              dotData: FlDotData(show: points.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                color: (color ?? t.brandGreen).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget dashboardChartCard({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final t = context.pharmaTokens;
  return PharmaSurface(
    padding: t.density.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.erpOverline.copyWith(
                color: t.textMuted,
              ),
        ),
        SizedBox(height: t.density.md),
        Expanded(child: child),
      ],
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
}) {
  final t = context.pharmaTokens;
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  final activeSlices = slices.where((slice) => slice.value > 0).toList(growable: false);

  if (total <= 0 && activeSlices.isEmpty) {
    return _dashboardChartEmptyState(context);
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

Future<void> dashboardReportExport({
  required WidgetRef ref,
  required String path,
  required DashboardQuery query,
  String format = 'csv',
}) async {
  final controller = ref.read(reportControllerProvider.notifier);
  final params = query.toParams();

  switch (format) {
    case 'excel':
      await controller.exportExcel(path: path, queryParameters: params);
      return;
    case 'pdf':
      await controller.downloadPdf(path: path, queryParameters: params);
      return;
    case 'csv':
    default:
      await controller.exportCsv(path: path, queryParameters: params);
  }
}
