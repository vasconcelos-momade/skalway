import 'package:flutter/material.dart';

import '../../../../../shared/widgets/tables/enterprise_pagination.dart';

class EstoquePagination extends StatelessWidget {
  const EstoquePagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.isBusy = false,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final bool isBusy;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return EnterprisePagination(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      isBusy: isBusy,
      itemLabel: 'lotes',
      onPageChanged: onPageChanged,
      onPageSizeChanged: onPageSizeChanged,
    );
  }
}
