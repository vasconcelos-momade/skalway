import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../cards/enterprise_kpi_grid.dart';
import '../dialogs/enterprise_overlay_chrome.dart';

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

    // Sem padding horizontal extra: o shell ([PharmaScreenLayout.pagePadding])
    // já aplica s.md em mobile.
    const headerPadding = EdgeInsets.zero;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeaderTexts ||
            ((filters == null) && (actions != null && actions!.isNotEmpty)))
          Padding(
            padding: headerPadding,
            child: Row(
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
                      child: EnterpriseResponsiveActions(
                        actions: actions!,
                        alignment: WrapAlignment.end,
                        forceExpand: size == PharmaScreenSize.mobile,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (filters != null) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? s.sm : s.md),
          Padding(
            padding: headerPadding,
            child: _buildFiltersAndActionsRow(
              context: context,
              size: size,
              filters: filters!,
              actions: actions,
            ),
          ),
        ],
        if (kpis != null && kpis!.isNotEmpty) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? s.md : s.lg),
          Padding(
            padding: headerPadding,
            child: _buildKpis(context, size),
          ),
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
      // Safe Area top/bottom ficam no shell (AppBar / NavigationBar / Scaffold).
      return SingleChildScrollView(child: body);
    }

    return body;
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

    // Align actions with filter controls (not labels): labeled fields are taller
    // than bare buttons, so crossAxisAlignment.end keeps Exportar on the input row.
    if (size == PharmaScreenSize.mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            filters,
            SizedBox(width: s.sm),
            ...actionItems,
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: filters),
        SizedBox(width: s.sm),
        Wrap(
          spacing: s.sm,
          runSpacing: s.sm,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: actionItems,
        ),
      ],
    );
  }
}
