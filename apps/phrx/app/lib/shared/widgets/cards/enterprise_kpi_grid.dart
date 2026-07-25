import 'package:flutter/material.dart';

import '../../../core/theme/spacing.dart';
import '../../responsive/pharma_screen_layout.dart';
import 'enterprise_stat_card.dart';

export 'enterprise_stat_card.dart';

/// Grelha de KPIs com altura fixa — alinhada à movimentações (88px desktop).
class EnterpriseKpiGrid extends StatelessWidget {
  const EnterpriseKpiGrid({
    super.key,
    required this.cards,
    this.useDesktopRowWhenSingleLine = false,
    this.minCardWidth = 280,
  });

  final List<Widget> cards;
  final bool useDesktopRowWhenSingleLine;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final s = context.spacing;
    final screen = context.pharmaScreen;
    final cardHeight = PharmaScreenLayout.kpiCardHeight(screen);

    // Mobile: métricas em scroll horizontal (design system).
    if (screen == PharmaScreenSize.mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              SizedBox(
                width: 220,
                height: cardHeight,
                child: cards[i],
              ),
              if (i < cards.length - 1) SizedBox(width: s.sm),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = PharmaScreenLayout.kpiCrossAxisCount(constraints.maxWidth);
        final fitsSingleRow = cards.length <= cross;

        if (useDesktopRowWhenSingleLine &&
            screen == PharmaScreenSize.desktop &&
            fitsSingleRow) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: cards[i],
                  ),
                ),
                if (i < cards.length - 1) SizedBox(width: s.sm),
              ],
            ],
          );
        }

        final spacing = s.sm;
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : minCardWidth;
        final crossAxisCount = PharmaScreenLayout.adaptiveCrossAxisCount(
          availableWidth,
          minCardWidth,
        );
        final rows = <Widget>[];

        for (var i = 0; i < cards.length; i += crossAxisCount) {
          final rowChildren = cards.skip(i).take(crossAxisCount).toList();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < rowChildren.length; j++) ...[
                  if (j > 0) SizedBox(width: spacing),
                  Expanded(
                    child: SizedBox(
                      height: cardHeight,
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
      },
    );
  }
}

/// KPI compacto para painéis — densidade e tipografia do design system.
EnterpriseStatCard dashboardKpiCard({
  required String title,
  required String value,
  required IconData icon,
  StatCardAccent accent = StatCardAccent.neutral,
  String? subtitle,
}) {
  return EnterpriseStatCard(
    title: title,
    value: value,
    icon: icon,
    accent: accent,
    subtitle: subtitle,
    density: StatCardDensity.compact,
  );
}
