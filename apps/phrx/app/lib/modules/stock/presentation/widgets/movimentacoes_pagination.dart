import 'package:flutter/material.dart';

import '../../../../shared/widgets/tables/enterprise_pagination.dart';

/// Paginação unificada no padrão enterprise (delega para [EnterprisePagination]).
class MovimentacoesPagination extends StatelessWidget {
  const MovimentacoesPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isBusy,
    this.totalCount,
    this.itemsOnPage,
    this.itemLabel = 'registros',
    this.onPrev,
    this.onNext,
    this.onPageSizeChanged,
    this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isBusy;
  final int? totalCount;
  final int? itemsOnPage;
  final String itemLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageSizeChanged;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    return EnterprisePagination(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      hasMore: hasMore,
      itemsOnPage: itemsOnPage,
      isBusy: isBusy,
      itemLabel: itemLabel,
      onPageChanged: (nextPage) {
        if (onPageChanged != null) {
          onPageChanged!(nextPage);
          return;
        }
        if (nextPage < page) {
          onPrev?.call();
        } else if (nextPage > page) {
          onNext?.call();
        }
      },
      onPageSizeChanged: onPageSizeChanged ?? (_) {},
    );
  }
}
