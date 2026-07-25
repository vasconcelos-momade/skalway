import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import 'dashboard_widgets.dart';

/// Proporção preferida da área do gráfico (largura : altura).
const double kDashboardChartAspectRatio = 16 / 9;

/// Largura mínima de cada card antes de reduzir colunas.
const double kDashboardChartMinItemWidth = 480.0;

/// Envolve um gráfico para controlar o layout na grelha.
///
/// [fullWidth] força 1 card por linha (útil para séries diárias/mensais em web).
class DashboardChartSlot extends StatelessWidget {
  const DashboardChartSlot({
    super.key,
    required this.child,
    this.fullWidth = false,
  });

  final Widget child;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => child;
}

/// Grid responsivo de gráficos do dashboard.
class DashboardChartsSection extends StatelessWidget {
  const DashboardChartsSection({
    super.key,
    required this.charts,
    this.minChartWidth = kDashboardChartMinItemWidth,
    this.preferredAspectRatio = kDashboardChartAspectRatio,
    this.minChartHeight = kDashboardChartMinHeight,
    this.maxChartHeight = kDashboardChartMaxHeight,
  });

  final List<Widget> charts;
  final double minChartWidth;
  final double preferredAspectRatio;
  final double minChartHeight;
  final double maxChartHeight;

  static bool _isFullWidth(Widget widget) =>
      widget is DashboardChartSlot && widget.fullWidth;

  static Widget _unwrap(Widget widget) =>
      widget is DashboardChartSlot ? widget.child : widget;

  @override
  Widget build(BuildContext context) {
    if (charts.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : minChartWidth;
        final spacing = AppSpacing.lg;

        final crossAxisCount = PharmaScreenLayout.adaptiveCrossAxisCount(
          availableWidth,
          minChartWidth,
          maxColumns: 2,
        );

        final rows = <Widget>[];
        var gridBatch = <Widget>[];

        void flushGridBatch() {
          if (gridBatch.isEmpty) return;
          rows.add(
            _buildGridRow(
              charts: gridBatch,
              availableWidth: availableWidth,
              spacing: spacing,
              crossAxisCount: crossAxisCount,
            ),
          );
          gridBatch = [];
        }

        for (final chart in charts) {
          if (_isFullWidth(chart)) {
            flushGridBatch();
            rows.add(
              _buildFullWidthRow(
                chart: _unwrap(chart),
                availableWidth: availableWidth,
              ),
            );
          } else {
            gridBatch.add(_unwrap(chart));
          }
        }
        flushGridBatch();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildFullWidthRow({
    required Widget chart,
    required double availableWidth,
  }) {
    final height = (availableWidth / preferredAspectRatio)
        .clamp(minChartHeight, maxChartHeight)
        .toDouble();
    final aspectRatio = availableWidth / height;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: chart,
    );
  }

  Widget _buildGridRow({
    required List<Widget> charts,
    required double availableWidth,
    required double spacing,
    required int crossAxisCount,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < charts.length; i += crossAxisCount) {
      final rowChildren = charts.skip(i).take(crossAxisCount).toList();
      final currentCount = rowChildren.length;
      final currentItemWidth =
          (availableWidth - (currentCount - 1) * spacing) / currentCount;
      final targetCardHeight = (currentItemWidth / preferredAspectRatio)
          .clamp(minChartHeight, maxChartHeight)
          .toDouble();
      final currentAspectRatio = currentItemWidth / targetCardHeight;

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < rowChildren.length; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(
                child: AspectRatio(
                  aspectRatio: currentAspectRatio,
                  child: rowChildren[j],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (rows.length == 1) return rows.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }
}
