import 'package:flutter/material.dart';

import '../../../../../shared/widgets/tables/enterprise_pagination.dart';

/// Alias retrocompatível para [EnterprisePagination].
class ProdutoPagination extends StatelessWidget {
  const ProdutoPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.isBusy = false,
    this.itemLabel = 'registros',
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final bool isBusy;
  final String itemLabel;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return EnterprisePagination(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      isBusy: isBusy,
      itemLabel: itemLabel,
      onPageChanged: onPageChanged,
      onPageSizeChanged: onPageSizeChanged,
    );
  }
}
