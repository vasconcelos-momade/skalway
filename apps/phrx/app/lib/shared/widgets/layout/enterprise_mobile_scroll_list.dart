import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../cards/enterprise_list_card.dart';
import '../dialogs/enterprise_overlay_tokens.dart';
import 'pharma_pinned_sliver_header.dart';

typedef EnterpriseMobileItemBuilder = Widget Function(BuildContext context, int index);

/// Lista mobile com KPIs roláveis, cabeçalho sticky e carregamento incremental.
class EnterpriseMobileScrollList extends StatefulWidget {
  const EnterpriseMobileScrollList({
    super.key,
    this.kpis,
    this.errorText,
    required this.stickyHeader,
    required this.itemCount,
    required this.itemBuilder,
    this.hasMore = false,
    this.isLoading = false,
    this.onLoadMore,
    this.emptyMessage = 'Nenhum registo encontrado',
    this.totalCount,
    this.totalCountLabel,
    this.headerSlivers = const [],
  });

  final List<Widget>? kpis;
  final String? errorText;
  final Widget stickyHeader;
  final int itemCount;
  final EnterpriseMobileItemBuilder itemBuilder;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final String emptyMessage;
  final int? totalCount;
  final String? totalCountLabel;
  final List<Widget> headerSlivers;

  @override
  State<EnterpriseMobileScrollList> createState() => _EnterpriseMobileScrollListState();
}

class _EnterpriseMobileScrollListState extends State<EnterpriseMobileScrollList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading || widget.onLoadMore == null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isEmpty = widget.itemCount == 0;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (widget.errorText != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: s.md, right: s.md, bottom: s.sm),
              child: Text(
                widget.errorText!,
                style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
              ),
            ),
          ),
        ...widget.headerSlivers,
        if (widget.kpis != null && widget.kpis!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: s.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: s.md),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.kpis!.length; i++) ...[
                      SizedBox(width: 220, height: 80, child: widget.kpis![i]),
                      if (i < widget.kpis!.length - 1) SizedBox(width: s.sm),
                    ],
                  ],
                ),
              ),
            ),
          ),
        PharmaPinnedSliverHeader(child: widget.stickyHeader),
        if (isEmpty && widget.isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: DesignMetrics.iconMd,
                height: DesignMetrics.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
                ),
              ),
            ),
          )
        else if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                widget.emptyMessage,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.only(top: s.sm, bottom: s.sm),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == widget.itemCount) {
                    if (widget.isLoading) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: s.lg),
                        child: Center(
                          child: SizedBox(
                            width: DesignMetrics.iconMd,
                            height: DesignMetrics.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!widget.hasMore) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: s.lg),
                        child: Center(
                          child: Text(
                            'Fim da lista',
                            style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0) const EnterpriseListDivider(),
                      widget.itemBuilder(context, index),
                    ],
                  );
                },
                childCount: widget.itemCount + 1,
              ),
            ),
          ),
        if (widget.totalCount != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(s.md, 0, s.md, s.md),
              child: Text(
                widget.totalCountLabel ?? 'Total: ${widget.totalCount} registo(s)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}

/// Corpo de listagem adaptativo: desktop com toolbar/tabela/paginação; mobile com scroll list.
class EnterpriseAdaptiveListBody extends StatelessWidget {
  const EnterpriseAdaptiveListBody({
    super.key,
    required this.isMobile,
    required this.isLoading,
    this.errorText,
    this.desktopToolbar,
    required this.desktopContent,
    this.desktopPagination,
    required this.mobileList,
  });

  final bool isMobile;
  final bool isLoading;
  final String? errorText;
  final Widget? desktopToolbar;
  final Widget desktopContent;
  final Widget? desktopPagination;
  final Widget mobileList;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (isMobile) {
      return mobileList;
    }

    return Column(
      children: [
        if (isLoading) const LinearProgressIndicator(),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
            ),
          ),
        if (desktopToolbar != null)
          Padding(padding: EdgeInsets.only(bottom: s.md), child: desktopToolbar!),
        Expanded(child: desktopContent),
        ?desktopPagination,
      ],
    );
  }
}

/// Bottom sheet genérico para filtros mobile (scrim do Design System).
///
/// O [child] deve trazer o próprio chrome (muitos filtros já incluem título/ações).
Future<void> showEnterpriseFiltersSheet({
  required BuildContext context,
  required Widget child,
  String title = 'Filtros',
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: enterpriseOverlayScrim(context),
    builder: (_) => child,
  );
}
