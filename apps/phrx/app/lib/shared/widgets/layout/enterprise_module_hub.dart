import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../cards/enterprise_kpi_grid.dart';

/// Hub de módulo com grelha KPI adaptativa e cabeçalho denso em mobile/tablet.
class EnterpriseModuleHub extends StatelessWidget {
  const EnterpriseModuleHub({
    super.key,
    this.title,
    this.subtitle,
    this.tag,
    this.actions,
    this.kpis,
    required this.child,
    this.filters,
    this.scrollable = false,
    this.mobileKpisHorizontalScroll = false,
  });

  final String? title;
  final String? subtitle;
  final String? tag;
  final List<Widget>? actions;
  final List<EnterpriseStatCard>? kpis;
  final Widget child;

  /// Filtros opcionais com layout responsivo dentro da largura disponível.
  final Widget? filters;

  /// Corpo inteiro com scroll (painéis com muitos KPIs e gráficos).
  final bool scrollable;

  /// Em mobile, renderiza KPIs numa linha com scroll horizontal.
  final bool mobileKpisHorizontalScroll;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final size = context.pharmaScreen;
    final textTheme = context.typography;
    final titleStyle = context.erpPageTitle.copyWith(color: t.textPrimary);

    final hasHeaderTexts =
        (title != null && title!.isNotEmpty) ||
        (subtitle != null && subtitle!.isNotEmpty) ||
        (tag != null && tag!.isNotEmpty);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeaderTexts ||
            ((filters == null) && (actions != null && actions!.isNotEmpty)))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasHeaderTexts)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag != null && tag!.isNotEmpty) ...[
                        Text(
                          tag!.toUpperCase(),
                          style: textTheme.erpOverline.copyWith(
                            color: t.brandBlue,
                          ),
                        ),
                        SizedBox(
                          height: size == PharmaScreenSize.mobile
                              ? s.xxs
                              : s.xs,
                        ),
                      ],
                      if (title != null && title!.isNotEmpty) ...[
                        Text(
                          title!,
                          maxLines: size == PharmaScreenSize.mobile ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        SizedBox(
                          height: size == PharmaScreenSize.mobile ? s.xs : s.sm,
                        ),
                      ],
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: size == PharmaScreenSize.mobile ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.erpBodySecondary.copyWith(
                            color: t.textMuted,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                )
              else
                const Spacer(),
              if (filters == null && actions != null && actions!.isNotEmpty)
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      spacing: s.sm,
                      runSpacing: s.sm,
                      alignment: WrapAlignment.end,
                      children: actions!,
                    ),
                  ),
                ),
            ],
          ),
        if (filters != null) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? s.sm : s.md),
          _buildFiltersAndActionsRow(
            context: context,
            size: size,
            filters: filters!,
            actions: actions,
          ),
        ],
        if (kpis != null && kpis!.isNotEmpty) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? s.md : s.lg),
          _buildKpis(context, size),
        ],
        SizedBox(height: size == PharmaScreenSize.mobile ? s.md : s.lg),
        if (scrollable)
          child
        else
          Expanded(
            child: child,
          ),
      ],
    );

    if (scrollable) {
      return SafeArea(child: SingleChildScrollView(child: body));
    }

    return SafeArea(child: body);
  }

  Widget _buildKpis(BuildContext context, PharmaScreenSize size) {
    if (kpis == null || kpis!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (mobileKpisHorizontalScroll && size == PharmaScreenSize.mobile) {
      final s = context.spacing;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < kpis!.length; i++) ...[
              SizedBox(
                width: 220,
                height: PharmaScreenLayout.kpiCardHeight(size),
                child: kpis![i],
              ),
              if (i < kpis!.length - 1) SizedBox(width: s.sm),
            ],
          ],
        ),
      );
    }

    return EnterpriseKpiGrid(cards: kpis!);
  }

  static Widget _buildFiltersAndActionsRow({
    required BuildContext context,
    required PharmaScreenSize size,
    required Widget filters,
    List<Widget>? actions,
  }) {
    final hasActions = actions != null && actions.isNotEmpty;
    if (!hasActions) return filters;
    final s = context.spacing;

    final actionItems = actions;

    if (size == PharmaScreenSize.mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            filters,
            SizedBox(width: s.sm),
            ...actionItems,
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: filters),
        SizedBox(width: s.sm),
        Wrap(
          spacing: s.sm,
          runSpacing: s.sm,
          alignment: WrapAlignment.end,
          children: actionItems,
        ),
      ],
    );
  }
}
